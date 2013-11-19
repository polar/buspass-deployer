module DeployUnixFrontendOperations
  include DeployUnixOperations
  include DeployRemoteKeyOperations


  def array_match(m, xs)
    result = []
    for x in xs do
      match = m.match(x)
      if (match)
        result << match[1]
      end
    end
    return result
  end


  # Requires Endpoint of the Unix subtype

  def remote_user
    frontend.remote_user
  end
  
  def remote_host
    frontend.remote_host
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
    log "#{remote_user}@#{remote_host}: #{cmd}"
    result = Rush.bash unix_ssh_cmd(remote_host, ssh_cert, remote_user, cmd)
    if result
      result.split("\n").each do |line|
        log "#{remote_user}@#{remote_host}: #{line}"
      end
    else
      log "#{remote_user}@#{remote_host}: no result!"
    end
    return result
  end
  
  def unix_scp(path, remote_path)
    log "#{remote_user}@#{remote_host}: scp #{path} #{remote_path}"
    result = Rush.bash unix_scp_cmd(remote_host, ssh_cert, remote_user, path, remote_path)
    if result
      result.split("\n").each do |line|
        log "#{remote_user}@#{remote_host}: #{line}"
      end
    else
      log "#{remote_user}@#{remote_host}: no result!"
    end
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
    log "#{head}: Creating #{frontend.at_type} #{remote_user}@#{remote_host}. Should already exist!"
    case frontend.deployment_type
      when /unix/
        uadmin_unix_ssh("sudo adduser #{remote_user} --quiet --disabled-password || exit 0")
      when /ec2/
        uadmin_unix_ssh("sudo adduser #{remote_user} --create-home --user-group || exit 0")
    end
    uadmin_unix_ssh("sudo -u #{remote_user} mkdir -p ~#{remote_user}/.ssh")
    uadmin_unix_ssh("sudo -u #{remote_user} chmod 777 ~#{remote_user}/.ssh")
    file = pub_cert(ssh_cert)
    begin
      uadmin_unix_scp(file.path, "~#{remote_user}/.ssh/frontend-#{name}.pub")
      uadmin_unix_ssh("cat ~#{remote_user}/.ssh/frontend-#{name}.pub | sudo -u #{remote_user} tee -a ~#{remote_user}/.ssh/authorized_keys")
    rescue Exception => boom4
      log "#{head}: error creating ~#{remote_user}/.ssh/frontend-#{name}.pub on #{remote_host} - #{boom4} - trying to ignore"
    end
    file.unlink
    uadmin_unix_ssh("sudo chown -R #{remote_user}:#{remote_user} ~#{remote_user}")
    uadmin_unix_ssh("sudo -u #{remote_user} chmod 700 ~#{remote_user}/.ssh")
    uadmin_unix_ssh("echo \"#{remote_user} ALL=(ALL:ALL) NOPASSWD: /etc/init.d/nginx, /bin/ls, /bin/cp, /bin/mkdir, /bin/rm, /bin/cat\" | sudo tee /etc/sudoers.d/#{remote_user}")
    unix_ssh("ls -la")
    unix_ssh("test -e .rvm || \\curl -L https://get.rvm.io | bash -s stable --autolibs=read-fail")
    unix_ssh("test -e .rvm && bash --login -c \"rvm install #{ruby_version}\"")
    unix_ssh("test -e #{frontend.git_name} || git clone #{frontend.git_repository} -b #{frontend.git_refspec} #{frontend.git_name}")
    unix_ssh("cd #{frontend.git_name}; rm Gemfile.lock; git submodule init; git submodule update")
    unix_ssh("bash --login -c \"cd ~/#{frontend.git_name}; bundle install\"")
    unix_ssh("cd ~/#{frontend.git_name}; bash scripts/create_frontend.sh #{frontend.git_name}")
    log "#{head}: Remote #{frontend.at_type} #{remote_user}@#{remote_host} exists."
    set_status("Success:Create")
  rescue Exception => boom
    log "#{head}: error creating ~#{remote_user}@#{remote_host} on remote server - #{boom}"
    set_status("Error:Create")
  end

  def unix_remote_frontend_exists?
    head = __method__
    set_status("Exists")
    # Created in this sense means I can log on with the proper credentials.
    log "#{head}: Checking if remote #{frontend.at_type} #{remote_user}@#{remote_host} exists!"
    unix_ssh("ls ~#{remote_user}/.ssh/frontend-#{name}.pub")
    log "#{head}: Remote #{frontend.at_type} #{remote_user}@#{remote_host} exists."
    set_status("Success:Exists")
    return true
  rescue Exception => boom
    log "#{head}: error ssh to remote server #{boom}"
    log "#{head}: Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host} does not exist."
    set_status("Error:Exists")
    return false
  end

  def unix_get_remote_frontend_deployment_status
    head = __method__
    set_status("DeployStatus")
    log "#{head}: Getting deploy frontend #{remote_user}@#{app_name} status."
    result = unix_ssh("cd #{frontend.git_name}; git log | head -3")
    state.git_commit = result
    set_status("Success:DeployStatus")
    log "#{head}: Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host} - #{state.git_commit.inspect} - updated_at #{state.updated_at}"
  rescue Exception => boom
    log "#{head}: Error getting Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host} deploy status - #{boom}"
    set_status("Error:DeployStatus", ["Could not get status"])
  end

  def unix_configure_remote_frontend
    head = __method__
    set_status("Configure")
    log "#{head}: Setting configuration variables for Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host}."
    file = Tempfile.new('vars')
    vars = frontend.remote_configuration
    vars.each_pair do |k,v|
      file.write("export #{k}='#{v}'\n")
    end
    file.close
    result = unix_scp(file.path, ".frontend-#{frontend.name}.env")
    file.unlink
    uadmin_unix_ssh("echo \"include `echo ~#{remote_user}/#{frontend.git_name}`/backends.d/*.conf;\" | sudo tee /etc/nginx/conf.d/frontend-#{frontend.name}.conf")
    unix_ssh("mkdir -p #{frontend.git_name}/backends.d")
    unix_ssh("bash --login -c \"source .frontend-#{frontend.name}.env; cd #{frontend.git_name}; bash #{frontend.configure_command} #{frontend.name}\"")
    set_status("Success:Configure")
  rescue Exception => boom
    log "#{head}: Cannot configure  Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host} - #{boom}"
    set_status("Error:ConfigureRemoteFrontend")
  end

  def unix_deploy_to_remote_frontend
    head = __method__
    set_status("Deploy")
    log "#{head}: Deploying frontend #{remote_user}@#{remote_host}"
    unix_ssh("test -e #{frontend.git_name} || git clone #{frontend.git_repository} -b #{frontend.git_refspec}")
    unix_ssh("cd #{frontend.git_name}; rm Gemfile.lock; git pull; git submodule init; git submodule update")
    unix_ssh("bash --login -c \"source .frontend-#{frontend.name}.env; cd #{frontend.git_name}; bundle install\"")
    log "#{head}: Created Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host}"
    set_status("Success:Deploy")
  rescue Exception => boom
    log "#{head}: Could not deploy Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host} : #{boom}"
    set_status("Error:Deploy")
  end

  def unix_destroy_remote_frontend
    head = __method__
    if !state.state_destroy
      set_status("Destroy")
      log "Deleting Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host}"
      begin
        unix_ssh("ls .frontend-#{frontend.name}.env")
        unix_ssh("rm -f .frontend-#{frontend.name}.env")
        unix_ssh("rm -f .ssh/frontend-#{frontend.name}.pub")
          # TODO: Remove the pub from the authorized keys.
      rescue Rush::BashFailed
        log "#{head}: Could not destroy Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host} : #{boom}"
        return
      end
      unix_ssh("ls -a .frontend-*.env")
      # If there is no .frontend-*.env, then we remove all the frontends.
      unix_ssh("test -e .frontend-*.env || rm -rf #{frontend.git_name}")
      uadmin_unix_ssh("test `ls ~#{remote_user} | wc -l` == '0' && sudo deluser --remove-home #{remote_user}")
      state.state_destroy = true
      set_status("Success:DestroyApp")
    end

    if !frontend.backends.empty?
      job = DeployFrontendJob.get_job(frontend, "destroy_remote_frontend")
      Delayed::Job.enqueue(job, :queue => "deploy-web", :run_at => Time.now + 1.minute)
    else
      frontend.destroy
      # TODO: We need a job to destroy us?
      set_status("Success::Destroy")
      self.destroy
    end
  rescue Exception => boom
    log "#{head}: Could not delete Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host} : #{boom}"
    set_status("Error:DestroyApp")
  end

  def unix_start_remote_frontend
    head = __method__
    set_status("Start")
    cmd = frontend.start_command
    log "#{head}: Starting Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host}."
    env_cmd = "source ~/.frontend-#{name}.env; cd #{frontend.git_name}; #{cmd} #{name}"
    unix_ssh("bash --login -c \"#{env_cmd}\"")
    set_status("Success:Start")
  rescue Exception => boom
    set_status("Error:Start")
    log "#{head}: error in starting Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host} - #{boom}."
  end

  def unix_stop_remote_frontend
    head = __method__
    set_status("Stop")
    cmd = frontend.stop_command
    log "#{head}: Starting Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host}."
    env_cmd = "source ~/.frontend-#{name}.env; cd #{frontend.git_name}; #{cmd} #{name}"
    unix_ssh("bash --login -c \"#{env_cmd}\"")
    set_status("Success:Stop")
  rescue Exception => boom
    set_status("Error:Stop")
    log "#{head}: error in stopping Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host} - #{boom}."
  end

  def unix_restart_remote_frontend
    head = __method__
    set_status("Restart")
    cmd = frontend.restart_command
    log "#{head}: Starting Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host}."
    env_cmd = "source ~/.frontend-#{name}.env; cd #{frontend.git_name}; #{cmd} #{name}"
    unix_ssh("bash --login -c \"#{env_cmd}\"")
    set_status("Success:Restart")
  rescue Exception => boom
    set_status("Error:Restart")
    log "#{head}: error in restarting Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host} - #{boom}."
  end

  def unix_status_remote_frontend
    head = __method__
    set_status("Status")
    log "#{head}: Status Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host}."

    cmd = "git log --max-count=1"
    env_cmd = "source ~/.frontend-#{name}.env; cd #{frontend.git_name}; #{cmd}"
    result = unix_ssh("bash --login -c \"#{env_cmd}\"")
    if result
      result = result.split("\n")
    end
    state.git_commit = result.take(4)

    netstat = unix_ssh("netstat -tan").split("\n")
    state.listen_status = ["#{frontend.remote_host}(#{frontend.external_ip})"]
    state.listen_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+([0-9a-f\:\.]*:80)\s+.*\s+LISTEN/, netstat)
    state.listen_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+([0-9a-f\:\.]*:443)\s+.*\s+LISTEN/, netstat)

    state.connection_status = []
    state.connection_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+([0-9a-f\:\.]*:80)\s+.*\s+ESTABLISHED/, netstat)
    state.connection_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+([0-9a-f\:\.]*:443)\s+.*\s+ESTABLISHED/, netstat)
    set_status("Success:Status", state.listen_status.length > 1 ? "UP" : "DOWN")

  rescue Exception => boom
    set_status("Error:Status")
    log "#{head}: error in restarting Remote Unix #{frontend.at_type} #{remote_user}@#{remote_host} - #{boom}."
  end

end