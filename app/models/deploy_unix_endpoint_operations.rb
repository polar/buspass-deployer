module DeployUnixEndpointOperations
  include DeployUnixOperations
  
  # Requires Endpoint of the Unix subtype
  
  def remote_user
    endpoint.remote_user
  end
  
  def remote_host
    endpoint.remote_host
  end

  def name
    endpoint.name
  end

  def ruby_version
    "1.9.3"
  end
  
  def uadmin_unix_ssh(cmd)
    log "uadmin@#{remote_host}: #{cmd}"
    result = Rush.bash unix_ssh_cmd(remote_host, ssh_cert, "uadmin", cmd)
    log "uadmin@#{remote_host}: Result #{result.inspect}"
    return result
  end

  def uadmin_unix_scp(path, remote_path)
    log "uadmin@#{remote_host}: scp #{path} #{remote_path}"
    result = Rush.bash unix_scp_cmd(remote_host, ssh_cert, "uadmin", path, remote_path)
    log "uadmin@#{remote_host}: Result #{result.inspect}"
    return result
  end

  def unix_ssh(cmd)
    log "#{remote_user}@#{remote_host}: #{cmd}"
    result = Rush.bash unix_ssh_cmd(remote_host, ssh_cert, remote_user, cmd)
    log "#{remote_user}@#{remote_host}: Result #{result.inspect}"
    return result
  end
  
  def unix_scp(path, remote_path)
    log "#{remote_user}@#{remote_host}: scp #{path} #{remote_path}"
    result = Rush.bash unix_scp_cmd(remote_host, ssh_cert, remote_user, path, remote_path)
    log "#{remote_user}@#{remote_host}: Result #{result.inspect}"
    return result
  end
  
  #
  # This uses the "uadmin" administrative account on the remote unix box to
  # create a home directory and add the ssh access key to the user's authorized_keys
  # so that we may login as that use for creating deploys.
  #
  def unix_create_remote_endpoint
    head = __method__
    set_status("Create")
    log "#{head}: Creating #{endpoint.at_type} #{remote_user}@#{remote_host}. Should already exist!"
    uadmin_unix_ssh("sudo adduser #{remote_user} --quiet --disabled-password || exit 0")
    uadmin_unix_ssh("sudo -u #{remote_user} mkdir -p ~#{remote_user}/.ssh")
    uadmin_unix_ssh("sudo -u #{remote_user} chmod 777 ~#{remote_user}/.ssh")
    file = pub_cert(ssh_cert)
    begin
      uadmin_unix_scp(file.path, "~#{remote_user}/.ssh/endpoint-#{name}.pub")
      uadmin_unix_ssh("cat ~#{remote_user}/.ssh/endpoint-#{name}.pub | sudo -u #{remote_user} tee -a ~#{remote_user}/.ssh/authorized_keys")
    rescue Exception => boom4
      log "#{head}: error creating ~#{remote_user}/.ssh/endpoint-#{name}.pub on #{remote_host} - #{boom4} - trying to ignore"
    end
    file.unlink
    uadmin_unix_ssh("sudo chown -R #{remote_user}:#{remote_user} ~#{remote_user}")
    uadmin_unix_ssh("sudo -u #{remote_user} chmod 700 ~#{remote_user}/.ssh")
    unix_ssh("ls -la")
    unix_ssh("test -e .rvm || \\curl -L https://get.rvm.io | bash -s stable --autolibs=read-fail")
    unix_ssh("test -e .rvm && bash --login -c \"rvm install #{ruby_version}\"")
    log "#{head}: Remote #{endpoint.at_type} #{remote_user}@#{remote_host} exists."
    set_status("Success:Create")
  rescue Exception => boom
    log "#{head}: error creating ~#{remote_user}@#{remote_host} on remote server - #{boom}"
    set_status("Error:Create")
  end

  def unix_remote_endpoint_exists?
    head = __method__
    set_status("Exists")
    # Created in this sense means I can log on with the proper credentials.
    log "#{head}: Checking if remote #{endpoint.at_type} #{remote_user}@#{remote_host} exists!"
    unix_ssh("ls ~#{remote_user}/.ssh/endpoint-#{name}.pub")
    log "#{head}: Remote #{endpoint.at_type} #{remote_user}@#{remote_host} exists."
    set_status("Success:Exists")
    return true
  rescue Exception => boom
    log "#{head}: error ssh to remote server #{boom}"
    log "#{head}: Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host} does not exist."
    set_status("Error:Exists")
    return false
  end

  def unix_get_deployment_status
    head = __method__
    set_status("DeployStatus")
    log "#{head}: Getting deploy swift endpoint #{remote_user}@#{remote_host} status."
    result = unix_ssh("cd #{endpoint.git_name}; git log | head -3")
    state.git_commit = result
    state.save
    set_status("Success:DeployStatus")
    log "#{head}: Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host} - #{state.git_commit.inspect} - updated_at #{state.updated_at}"
  rescue Exception => boom
    log "#{head}: Error getting Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host} deploy status - #{boom}"
    set_status("Error:DeployStatus", ["Could not get status"])
  end

  def unix_configure_remote_endpoint
    head = __method__
    set_status("Configure")
    log "#{head}: Setting configuration variables for Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host}."
    file = Tempfile.new('vars')
    vars = endpoint.remote_configuration
    vars.each_pair do |k,v|
      file.write("export #{k}='#{v}'\n")
    end
    file.close
    result = unix_scp(file.path, ".endpoint-#{endpoint.name}.env")
    file.unlink
    set_status("Success:Configure", [result])
  rescue Exception => boom
    log "#{head}: Cannot configure  Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host} - #{boom}"
    set_status("Error:ConfigureRemoteEndpoint")
  end

  def unix_deploy_to_remote_endpoint
    head = __method__
    set_status("Deploy")
    log "#{head}: Deploying swift endpoint #{remote_user}@#{remote_host}"
    unix_ssh("test -e #{endpoint.git_name} || git clone #{endpoint.git_repository} -b #{endpoint.git_refspec}")
    unix_ssh("cd #{endpoint.git_name}; rm Gemfile.lock; git pull; git submodule init; git submodule update")
    unix_ssh('bash --login -c "cd '+endpoint.git_name+'; bundle install" ')
    log "#{head}: Created Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host}"
    set_status("Success:Deploy")
  rescue Exception => boom
    log "#{head}: Could not deploy Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host} : #{boom}"
    set_status("Error:Deploy")
  end

  def unix_destroy_remote_endpoint
    head = __method__
    set_status("DestroyApp")
    log "Deleting Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host}"
    begin
      #unix_ssh("ls .endpoint-#{endpoint.name}.env")
      unix_ssh("rm -f .endpoint-#{endpoint.name}.env")
      unix_ssh("rm -f .ssh/endpoint-#{endpoint.name}.pub")
        # TODO: Remove the pub from the authorized keys.
    rescue Rush::BashFailed => boom
      log "#{head}: Could not destroy Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host} : #{boom}"
      return
    end
    # If there is no .endpoint-*.env, then we remove all the endpoints.
    unix_ssh("test -e .endpoint-*.env || rm -rf #{endpoint.git_name}")
    begin
      # If the test doesn't pass, which is what we normally want,, then it raises Rush::BashFailed
      # so, we ignore.
      uadmin_unix_ssh("test `ls ~#{remote_user} | wc -l` == '0' && sudo deluser --remove-home #{remote_user}")
    rescue
    end
    set_status("Success:DestroyApp")
  rescue Exception => boom
    log "#{head}: Could not delete Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host} : #{boom}"
    set_status("Error:DestroyApp")
  end

  def unix_start_remote_endpoint
    head = __method__
    set_status("Start")
    cmd = endpoint.start_command
    log "#{head}: Starting Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host}."
    env_cmd = "source ~/.endpoint-#{name}.env; cd #{endpoint.git_name}; bash #{cmd} #{name}"
    unix_ssh("bash --login -c \"#{env_cmd}\"")
    set_status("Success:Start")
  rescue Exception => boom
    set_status("Error:Start")
    log "#{head}: error in starting Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host} - #{boom}."
  end

  def unix_stop_remote_endpoint
    head = __method__
    set_status("Stop")
    cmd = endpoint.stop_command
    log "#{head}: Starting Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host}."
    env_cmd = "source ~/.endpoint-#{name}.env; cd #{endpoint.git_name}; bash #{cmd} #{name}"
    unix_ssh("bash --login -c \"#{env_cmd}\"")
    set_status("Success:Stop")
  rescue Exception => boom
    set_status("Error:Stop")
    log "#{head}: error in stopping Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host} - #{boom}."
  end

  def unix_restart_remote_endpoint
    head = __method__
    set_status("Restart")
    cmd = endpoint.restart_command
    log "#{head}: Starting Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host}."
    env_cmd = "source ~/.endpoint-#{name}.env; cd #{endpoint.git_name}; bash #{cmd} #{name}"
    unix_ssh("bash --login -c \"#{env_cmd}\"")
    set_status("Success:Restart")
  rescue Exception => boom
    set_status("Error:Restart")
    log "#{head}: error in restarting Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host} - #{boom}."
  end

  def unix_status_remote_endpoint
    head = __method__
    set_status("RemoteStatus")
    proxy = endpoint.server_proxy
    state.listen_status = ["#{endpoint.external_ip}"]
    if proxy
      netstat = unix_ssh("netstat -tan").split("\n")
      case proxy.proxy_type
        when "Server"
          addr = proxy.proxy_address
          match = /(.*):(.*)/.match addr
          host = match[1]
          port = match[2]
          address = "0.0.0.0:#{port}"
          state.listen_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+(#{address.gsub(".","\\.")})\s+.*\s+LISTEN/, netstat)
        when "SSH"
          addr = proxy.proxy_address
          match = /(.*):(.*)/.match addr
          host = match[1]
          port = match[2]
          address = "#{endpoint.frontend.external_ip}:#{port}"
          state.listen_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+[0-9\.\:]+\s+(#{address.gsub(".","\\.")})\s+.*\s+ESTABLISHED/, netstat)
        when "Swift"
          addr = proxy.backend_address
          match = /(.*):(.*)/.match addr
          host = match[1]
          port = match[2]
          address = "#{endpoint.frontend.external_ip}:#{port}"
          state.listen_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+[0-9\.\:]+\s+(#{address.gsub(".","\\.")})\s+.*\s+ESTABLISHED/, netstat)
      end
    end
    set_status("Success:Restart", state.listen_status.length > 1 ? "UP" : "DOWN")
  rescue Exception => boom
    set_status("Error:Restart")
    log "#{head}: error in restarting Remote Unix #{endpoint.at_type} #{remote_user}@#{remote_host} - #{boom}."
  end


end