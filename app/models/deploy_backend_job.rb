class DeployBackendJob < DeployJob
  include DeployUnixBackendOperations

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

  def listen_status
    state.listen_status
  end

  def connection_status
    state.connection_status
  end

  def dir
    backend.frontend.git_name
  end

  def create_remote_backend
    log "#{head}: Create Remote Backend #{backend.name} on Frontend #{frontend.name}; Nothing to be done"
  end

  def configure_remote_backend
    head = __method__
    log "#{head}: Configuring Remote Backend #{backend.name} on Frontend #{frontend.name}"
    set_status("Configure")
    result = unix_ssh("bash -login -c \"source ~/.frontend-#{frontend.name}.env; cd #{dir}; #{backend.configure_command} #{backend.name}\"")
    set_status("Success:Configure")
  rescue Exception => boom
    log "#{head}: Error #{boom}"
    set_status("Error:Configure")
  end

  def deconfigure_remote_backend
    head = __method__
    log "#{head}: Deconfiguring Remote Backend #{backend.name} on Frontend #{frontend.name}"
    set_status("Deconfigure")
    result = unix_ssh("bash -login -c \"source ~/.frontend-#{frontend.name}.env; cd #{dir}; #{backend.deconfigure_command} #{backend.name}\"")
    set_status("Success:Deconfigure")
  rescue Exception => boom
    log "#{head}: Error #{boom}"
    set_status("Error:Deconfigure")
  end

  def deploy_to_remote_backend
    head = __method__
    log "#{head}: Deploy Remote Backend #{backend.name} on Frontend #{frontend.name}; Nothing to be done"
  end

  def start_remote_backend
    head = __method__
    log "#{head}: Start Remote Backend #{backend.name} on Frontend #{frontend.name}"
    set_status("Start")
    result = unix_ssh("bash -login -c \"source ~/.frontend-#{frontend.name}.env; cd #{dir}; #{backend.start_command} #{backend.name}\"")
    set_status("Success:Start")
  rescue Exception => boom
    log "#{head}: Error #{boom}"
    set_status("Error:Start")
  end

  def stop_remote_backend
    head = __method__
    log "#{head}: Stop Remote Backend #{backend.name} on Frontend #{frontend.name}"
    set_status("Stop")
    result = unix_ssh("bash -login -c \"source ~/.frontend-#{frontend.name}.env; cd #{dir}; #{backend.stop_command} #{backend.name}\"")
    set_status("Success:Stop")
  rescue Exception => boom
    log "#{head}: Error #{boom}"
    set_status("Error:Stop")
  end

  def restart_remote_backend
    head = __method__

    log "#{head}: Restart Remote Backend #{backend.name} on Frontend #{frontend.name}"
    log "#{head}: Stop Remote Backend #{backend.name} on Frontend #{frontend.name}"
    set_status("Stop")
    result = unix_ssh("bash -login -c \"source ~/.frontend-#{frontend.name}.env; cd #{dir}; #{backend.stop_command} #{backend.name}\"")
    set_status("Success:Stop")
    log "#{head}: Start Remote Backend #{backend.name} on Frontend #{frontend.name}"
    set_status("Start")
    result = unix_ssh_cmd(remote_host, cert, remote_user, "bash -login -c \"source ~/.frontend-#{frontend.name}.env; cd #{dir}; #{backend.stop_command} #{backend.name}\"")
    set_status("Success:Start")
    set_status("Success:Restart")
  rescue Exception => boom
    log "#{head}: Error #{boom}"
    set_status("Error:Restart")
  end

  def destroy_remote_backend
    head = __method__

    if !state.state_destroy
      log "#{head}: Destroy Remote Backend #{backend.name} on Frontend #{frontend.name}"
      log "#{head}: Stop Remote Backend #{backend.name} on Frontend #{frontend.name}"
      set_status("Stop")
      result = unix_ssh_cmd(remote_host, remote_key, remote_user, "bash -login -c \"source ~/.frontend-#{frontend.name}.env; cd #{git_name}; script/stop_backend.sh --name #{backend.name}\"")
      set_status("Success:Stop")
      state.state_destroy = true
      deconfigure_remote_backend
      set_status("Destroy")
      destroy_all_endpoints
    end
    if !backend.endpoints.empty?
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

  def status_remote_backend
    head = __method__
    log "#{head}: Status #{backend.name} on Frontend #{frontend.name}"
    set_status("Status")

    netstat = unix_ssh("netstat -tan").split("\n")
    state.listen_status = ["#{frontend.remote_host}(#{frontend.external_ip})"]
    backend.server_proxies.each do |proxy|
      case proxy.proxy_type
        when "Server"
        when "SSH"
          state.listen_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+(#{proxy.local_proxy_address.gsub(".","\\.")})\s+.*\s+LISTEN/, netstat)
        when "Swift"
          state.listen_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+(#{proxy.local_proxy_address.gsub(".","\\.")})\s+.*\s+LISTEN/, netstat)
          state.listen_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+(#{proxy.local_backend_address.gsub(".","\\.")})\s+.*\s+LISTEN/, netstat)
      end
    end
    state.listen_status = state.listen_status.uniq.map{|x| "#{x} *"}

    state.connection_status = []
    backend.server_proxies.each do |proxy|
      case proxy.proxy_type
        when "Server"
          uri = URI.parse(proxy.proxy_address)
          proxy_address = "[0-9a-fA-F.:]+:#{uri.port}"
          state.connection_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+(#{proxy_address}\s+.*)\s+ESTABLISHED/, netstat)
        when "SSH"
          uri = URI.parse("http://"+proxy.local_proxy_address)
          proxy_address = "[0-9a-fA-F.:]+:#{uri.port}"
          state.connection_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+(#{proxy_address}\s+.*)\s+ESTABLISHED/, netstat)
        when "Swift"
          uri = URI.parse("http://"+proxy.local_proxy_address)
          proxy_address = uri.host == "0.0.0.0" ? "[0-9a-fA-F.:]+:#{uri.port}" : "#{uri.host.gsub(".","\\.")}:#{uri.port}"
          uri = URI.parse("http://"+proxy.local_backend_address)
          backend_address = uri.host == "0.0.0.0" ? "[0-9a-fA-F.:]+:#{uri.port}" : "#{uri.host.gsub(".","\\.")}:#{uri.port}"
          state.connection_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+(#{proxy_address}\s+.*)\s+ESTABLISHED/, netstat)
          state.connection_status += array_match(/tcp\s+[0-9]+\s+[0-9]+\s+(#{backend_address}\s+.*)\s+ESTABLISHED/, netstat)
      end
    end

    set_status("Success:Status")
    log "#{head}: Listen status #{state.listen_status.join(" ")}"
    log "#{head}: Connection status #{state.connection_status.join(" ")}"
    set_status("Success:Status", state.listen_status.length > 1 ? "UP" : "DOWN")
  rescue Exception => boom
    set_status("Error:Status")
    log "#{head}: error in restarting Remote #{frontend.at_type} #{remote_user}@#{remote_host} - #{boom}."
  end

  def apply_to_endpoint(method, endpoint)
    if endpoint && endpoint.backend == self.backend
      job = DeployEndpointJob.get_job(endpoint, method)
      Delayed::Job.enqueue(djob, :queue => "deploy-web")
    end
  end

  def start_all_endpoints
    backend.endpoints.each do |endpoint|
      apply_to_endpoint("start_remote_endpoint", endpoint)
    end
  end

  def restart_all_endpoints
    backend.endpoints.each do |endpoint|
      apply_to_endpoint("restart_remote_endpoint", endpoint)
    end
  end

  def stop_all_endpoints
    backend.endpoints.each do |endpoint|
      apply_to_endpoint("stop_remote_endpoint", endpoint)
    end
  end

  def deploy_to_all_endpoints
    backend.endpoints.each do |endpoint|
      apply_to_endpoint("deploy_to_remote_endpoint", endpoint)
    end
  end

  def destroy_all_endpoints
    backend.endpoints.each do |endpoint|
      apply_to_endpoint("destroy_remote_endpoint", endpoint)
    end
  end

  def self.get_job(backend, action)
    job = DeployBackendJob.where(:backend_id => backend.id).first
    if job.nil?
      job = DeployBackendJob.new(:backend => backend)
      job.save
    end
    DeployBackendJobspec.new(job.id, action, backend.name)
  end

end