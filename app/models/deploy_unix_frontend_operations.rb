module DeployUnixFrontendOperations
  include DeployUnixOperations
  
  # Requires Endpoint of the Unix subtype
  
  def user_name
    frontend.remote_user
  end
  
  def remote_host
    frontend.remote_host
  end

  def ssh_cert
    frontend.remote_key
  end

  def admin_user
    frontend.admin_user
  end

  def name
    frontend.name
  end

  def ruby_version
    "1.9.3"
  end
  
  def uadmin_unix_ssh(cmd)
    log "#{admin_user}@#{remote_host}: #{cmd}"
    result = Rush.bash unix_ssh_cmd(remote_host, ssh_cert, "uadmin", cmd)
    log "#{admin_user}@#{remote_host}: Result #{result.inspect}"
    return result
  end

  def uadmin_unix_scp(path, remote_path)
    log "#{admin_user}@#{remote_host}: scp #{path} #{remote_path}"
    result = Rush.bash unix_scp_cmd(remote_host, ssh_cert, "uadmin", path, remote_path)
    log "#{admin_user}@#{remote_host}: Result #{result.inspect}"
    return result
  end

  def unix_ssh(cmd)
    log "#{user_name}@#{remote_host}: #{cmd}"
    result = Rush.bash unix_ssh_cmd(remote_host, ssh_cert, user_name, cmd)
    log "#{user_name}@#{remote_host}: Result #{result.inspect}"
    return result
  end
  
  def unix_scp(path, remote_path)
    log "#{user_name}@#{remote_host}: scp #{path} #{remote_path}"
    result = Rush.bash unix_scp_cmd(remote_host, ssh_cert, user_name, path, remote_path)
    log "#{user_name}@#{remote_host}: Result #{result.inspect}"
    return result
  end
  
  #
  # This uses the "uadmin" administrative account on the remote unix box to
  # create a home directory and add the ssh access key to the user's authorized_keys
  # so that we may login as that use for creating deploys.
  #
  def unix_create_remote_frontend
    head = __method__
    set_status("Create")
    log "#{head}: Creating #{frontend.at_type} #{user_name}@#{remote_host}. Should already exist!"
    uadmin_unix_ssh("sudo adduser #{user_name} --quiet --disabled-password || exit 0")
    uadmin_unix_ssh("sudo -u #{user_name} mkdir -p ~#{user_name}/.ssh")
    uadmin_unix_ssh("sudo -u #{user_name} chmod 777 ~#{user_name}/.ssh")
    file = pub_cert(ssh_cert)
    begin
      uadmin_unix_scp(file.path, "~#{user_name}/.ssh/frontend-#{name}.pub")
      uadmin_unix_ssh("cat ~#{user_name}/.ssh/frontend-#{name}.pub | sudo -u #{user_name} tee -a ~#{user_name}/.ssh/authorized_keys")
    rescue Exception => boom4
      log "#{head}: error creating ~#{user_name}/.ssh/frontend-#{name}.pub on #{remote_host} - #{boom4} - trying to ignore"
    end
    log "#{head}: Result #{result.inspect}"
    file.unlink
    uadmin_unix_ssh("sudo chown -R #{user_name}:#{user_name} ~#{user_name}")
    uadmin_unix_ssh("sudo -u #{user_name} chmod 700 ~#{user_name}/.ssh")
    unix_ssh("ls -la")
    unix_ssh("test -e .rvm || \\curl -L https://get.rvm.io | bash -s stable --autolibs=read-fail")
    unix_ssh("test -e .rvm && bash --login -c \"rvm install #{ruby_version}\"")
    log "#{head}: Remote #{frontend.at_type} #{user_name}@#{remote_host} exists."
    set_status("Success:Create")
  rescue Exception => boom
    log "#{head}: error creating ~#{user_name}@#{remote_host} on remote server - #{boom}"
    set_status("Error:Create")
  end

  def unix_remote_frontend_exists?
    head = __method__
    set_status("Exists")
    # Created in this sense means I can log on with the proper credentials.
    log "#{head}: Checking if remote #{frontend.at_type} #{user_name}@#{remote_host} exists!"
    unix_ssh("ls ~#{user_name}/.ssh/frontend-#{name}.pub")
    log "#{head}: Remote #{frontend.at_type} #{user_name}@#{remote_host} exists."
    set_status("Success:Exists")
    return true
  rescue Exception => boom
    log "#{head}: error ssh to remote server #{boom}"
    log "#{head}: Remote Unix #{frontend.at_type} #{user_name}@#{remote_host} does not exist."
    set_status("Error:Exists")
    return false
  end

  def unix_get_remote_frontend_deployment_status
    head = __method__
    set_status("DeployStatus")
    log "#{head}: Getting deploy frontend #{user_name}@#{app_name} status."
    result = unix_ssh("cd #{frontend.git_name}; git log | head -3")
    state.git_commit = result
    set_status("Success:DeployStatus")
    log "#{head}: Remote Unix #{frontend.at_type} #{user_name}@#{remote_host} - #{state.git_commit.inspect} - updated_at #{state.updated_at}"
  rescue Exception => boom
    log "#{head}: Error getting Remote Unix #{frontend.at_type} #{user_name}@#{remote_host} deploy status - #{boom}"
    set_status("Error:DeployStatus", ["Could not get status"])
  end

  def unix_configure_remote_frontend
    head = __method__
    set_status("Configure")
    log "#{head}: Setting configuration variables for Remote Unix #{frontend.at_type} #{user_name}@#{remote_host}."
    file = Tempfile.new('vars')
    vars = frontend.remote_configuration
    vars.each_pair do |k,v|
      file.write("export #{k}='#{v}'\n")
    end
    file.close
    result = unix_scp(file.path, ".frontend-#{frontend.name}.env")
    file.unlink
    set_status("Success:Configure", [result])
  rescue Exception => boom
    log "#{head}: Cannot configure  Remote Unix #{frontend.at_type} #{user_name}@#{remote_host} - #{boom}"
    set_status("Error:ConfigureRemoteFrontend")
  end

  def unix_deploy_to_remote_frontend
    head = __method__
    set_status("Deploy")
    log "#{head}: Deploying frontend #{user_name}@#{app_name}"
    unix_ssh("test -e #{frontend.git_name} || git clone #{frontend.git_repository} -b #{frontend.git_refspec}")
    unix_ssh("cd #{frontend.git_name}; rm Gemfile.lock; git pull; git submodule init; git submodule update")
    unix_ssh("bash --login -c \"cd #{frontend.git_name}; bundle install\"")
    log "#{head}: Created Remote Unix #{frontend.at_type} #{user_name}@#{remote_host}"
    set_status("Success:Deploy")
  rescue Exception => boom
    log "#{head}: Could not deploy Remote Unix #{frontend.at_type} #{user_name}@#{remote_host} : #{boom}"
    set_status("Error:Deploy")
  end

  def unix_destroy_remote_frontend
    head = __method__
    set_status("DestroyApp")
    log "Deleting Remote Unix #{frontend.at_type} #{user_name}@#{remote_host}"
    begin
      unix_ssh("ls .frontend-#{frontend.name}.env")
      unix_ssh("rm -f .frontend-#{frontend.name}.env")
      unix_ssh("rm -f .ssh/frontend-#{frontend.name}.pub")
        # TODO: Remove the pub from the authorized keys.
    rescue Rush::BashFailed
      log "#{head}: Could not destroy Remote Unix #{frontend.at_type} #{user_name}@#{remote_host} : #{boom}"
      return
    end
    unix_ssh("ls -a .frontend-*.env")
    # If there is no .frontend-*.env, then we remove all the frontends.
    unix_ssh("test -e .frontend-*.env || rm -rf #{frontend.git_name}")
    uadmin_unix_ssh("test `ls ~#{user_name} | wc -l` == '0' && sudo deluser --remove-home #{user_name}")
    set_status("Success:DestroyApp")
  rescue Exception => boom
    log "#{head}: Could not delete Remote Unix #{frontend.at_type} #{user_name}@#{remote_host} : #{boom}"
    set_status("Error:DestroyApp")
  end

  def unix_start_remote_frontend
    head = __method__
    set_status("Start")
    cmd = frontend.start_command
    log "#{head}: Starting Remote Unix #{frontend.at_type} #{user_name}@#{remote_host}."
    env_cmd = "source ~/.frontend-#{name}.env; cd #{frontend.git_name}; #{cmd} #{name}"
    unix_ssh("bash --login -c \"#{env_cmd}\"")
    set_status("Success:Start")
  rescue Exception => boom
    set_status("Error:Start")
    log "#{head}: error in starting Remote Unix #{frontend.at_type} #{user_name}@#{remote_host} - #{boom}."
  end

  def unix_stop_remote_frontend
    head = __method__
    set_status("Stop")
    cmd = frontend.stop_command
    log "#{head}: Starting Remote Unix #{frontend.at_type} #{user_name}@#{remote_host}."
    env_cmd = "source ~/.frontend-#{name}.env; cd #{frontend.git_name}; #{cmd} #{name}"
    unix_ssh("bash --login -c \"#{env_cmd}\"")
    set_status("Success:Stop")
  rescue Exception => boom
    set_status("Error:Stop")
    log "#{head}: error in stopping Remote Unix #{frontend.at_type} #{user_name}@#{remote_host} - #{boom}."
  end

  def unix_restart_remote_frontend
    head = __method__
    set_status("Restart")
    cmd = frontend.restart_command
    log "#{head}: Starting Remote Unix #{frontend.at_type} #{user_name}@#{remote_host}."
    env_cmd = "source ~/.frontend-#{name}.env; cd #{frontend.git_name}; #{cmd} #{name}"
    unix_ssh("bash --login -c \"#{env_cmd}\"")
    set_status("Success:Restart")
  rescue Exception => boom
    set_status("Error:Restart")
    log "#{head}: error in restarting Remote Unix #{frontend.at_type} #{user_name}@#{remote_host} - #{boom}."
  end

  def unix_destroy_remote_frontend
    head = __method__
    set_status("Destroy")
    cmd = frontend.restart_command
    log "#{head}: Starting Remote Unix #{frontend.at_type} #{user_name}@#{remote_host}."
    env_cmd = "source ~/.frontend-#{name}.env; cd #{frontend.git_name}; #{cmd} #{name}"
    unix_ssh("bash --login -c \"#{env_cmd}\"")
    set_status("Success:Destroy")
  rescue Exception => boom
    set_status("Error:Destroy")
    log "#{head}: error in restarting Remote Unix #{frontend.at_type} #{user_name}@#{remote_host} - #{boom}."
  end


end