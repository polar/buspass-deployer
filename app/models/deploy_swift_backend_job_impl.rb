class DeploySwiftBackendJobImpl
  include DeployUnixOperations

  def create_remote_backend
    log "#{head}: Create Remote Backend #{backend.name} on Frontend #{frontend.name}; Nothing to be done"
  end

  def configure_remote_backend
    head = __method__
    host = frontend.remote_host
    user = frontend.remote_user
    dir  = frontend.git_name

    log "#{head}: Configuring Remote Backend #{backend.name} on Frontend #{frontend.name}"
    set_status("Configure")
    result = unix_ssh_cmd(host, ssh_cert, user, "bash -login -c \"cd #{dir}; #{backend.configure_command} #{backend.name}\"")
    set_status("Success:Configure")
  rescue Exception => boom
    log "#{head}: Error #{boom}"
    set_status("Error:Configure")
  end

  def deploy_to_remote_backend
    log "#{head}: Deploy Remote Backend #{backend.name} on Frontend #{frontend.name}; Nothing to be done"
  end

  def start_remote_backend
    host = frontend.remote_host
    user = frontend.remote_user
    dir  = frontend.git_name

    log "#{head}: Start Remote Backend #{backend.name} on Frontend #{frontend.name}"
    set_status("Start")
    result = unix_ssh_cmd(host, ssh_cert, user, "bash -login -c \"cd #{dir}; #{backend.start_command} #{backend.name}\"")
    set_status("Success:Start")
  rescue Exception => boom
    log "#{head}: Error #{boom}"
    set_status("Error:Start")
  end

  def stop_remote_backend
    host = frontend.remote_host
    user = frontend.remote_user
    dir  = frontend.git_name

    log "#{head}: Stop Remote Backend #{backend.name} on Frontend #{frontend.name}"
    set_status("Stop")
    result = unix_ssh_cmd(host, ssh_cert, user, "bash -login -c \"cd #{dir}; #{backend.stop_command} #{backend.name}\"")
    set_status("Success:Stop")
  rescue Exception => boom
    log "#{head}: Error #{boom}"
    set_status("Error:Stop")
  end

  def restart_remote_backend
    host = frontend.remote_host
    user = frontend.remote_user
    cert = frontend.remote_key
    dir  = frontend.git_name

    log "#{head}: Restart Remote Backend #{backend.name} on Frontend #{frontend.name}"
    log "#{head}: Stop Remote Backend #{backend.name} on Frontend #{frontend.name}"
    set_status("Stop")
    result = unix_ssh_cmd(host, cert, user, "bash -login -c \"cd #{dir}; #{backend.stop_command} #{backend.name}\"")
    set_status("Success:Stop")
    log "#{head}: Start Remote Backend #{backend.name} on Frontend #{frontend.name}"
    set_status("Start")
    result = unix_ssh_cmd(host, cert, user, "bash -login -c \"cd #{dir}; #{backend.stop_command} #{backend.name}\"")
    set_status("Success:Start")
    set_status("Success:Restart")
  rescue Exception => boom
    log "#{head}: Error #{boom}"
    set_status("Error:Restart")
  end

  def destroy_remote_backend
    host = frontend.remote_host
    user = frontend.remote_user
    dir  = frontend.git_name

    if !state_destroy
      log "#{head}: Destroy Remote Backend #{backend.name} on Frontend #{frontend.name}"
      log "#{head}: Stop Remote Backend #{backend.name} on Frontend #{frontend.name}"
      set_status("Stop")
      result = unix_ssh_cmd(host, ssh_cert, user, "bash -login -c \"cd #{dir}; script/stop_backend.sh --name #{backend.name}\"")
      set_status("Success:Stop")
      self.state_destroy = true
      deconfigure_remote_backend
      set_status("Destroy")
      destroy_all_endpoints
    elsif !backend.endpoints.empty?
      job = DeployBackendJob.get_job(backend, "destroy_remote_backend")
      Delayed::Job.enqueue(job, :queue => "deploy-web", :run_at => Time.now + 1.minute)
    else
      backend.destroy
      # TODO: We need a job to destroy us?
      set_status("Success::Destroy")
      self.destroy
    end
  rescue Exception => boom
    log "#{head}: Error #{boom}"
    set_status("Error:Destroy")
  end
end