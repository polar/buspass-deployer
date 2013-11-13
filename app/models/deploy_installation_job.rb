class DeployInstallationJob < DeployJob

  def create_installation
    head = __method__
    log "#{head}: START"
    set_status("#{head}")
    for x in installation.frontends do
      job = DeployFrontendJob.get_job(x, "create_remote_frontend")
      log "#{head}: create_remnote_frontend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.backends do
      job = DeployBackendJob.get_job(x, "create_remote_backend")
      log "#{head}: create_remnote_backend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.endpoints do
      job = DeployEndpointJob.get_job(x, "create_remote_endpoint")
      log "#{head}: create_remnote_endpoint #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    set_status("Success:#{head}")
    log "#{head}: DONE"
  end

  def configure_installation
    head = __method__
    log "#{head}: START"
    set_status("#{head}")
    for x in installation.frontends do
      job = DeployFrontendJob.get_job(x, "configure_remote_frontend")
      log "#{head}: configure_remnote_frontend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.backends do
      job = DeployBackendJob.get_job(x, "configure_remote_backend")
      log "#{head}: configure_remnote_backend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.endpoints do
      job = DeployEndpointJob.get_job(x, "configure_remote_endpoint")
      log "#{head}: configure_remnote_endpoint #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    set_status("Success:#{head}")
    log "#{head}: DONE"
  end

  def deploy_to_installation
    head = __method__
    log "#{head}: START"
    set_status("#{head}")
    for x in installation.frontends do
      job = DeployFrontendJob.get_job(x, "deploy_to_remote_frontend")
      log "#{head}: deploy_to_remnote_frontend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.backends do
      job = DeployBackendJob.get_job(x, "deploy_to_remote_backend")
      log "#{head}: deploy_to_remote_backend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.endpoints do
      job = DeployEndpointJob.get_job(x, "deploy_to_remote_endpoint")
      log "#{head}: deploy_to_remote_endpoint #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    set_status("Success:#{head}")
    log "#{head}: DONE"
  end

  def start_installation
    head = __method__
    log "#{head}: START"
    set_status("#{head}")
    for x in installation.frontends do
      job = DeployFrontendJob.get_job(x, "start_remote_frontend")
      log "#{head}: start_remote_frontend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.backends do
      job = DeployBackendJob.get_job(x, "start_remote_backend")
      log "#{head}: start_remote_backend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.endpoints do
      job = DeployEndpointJob.get_job(x, "start_remote_endpoint")
      log "#{head}: start_remote_endpoint #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    set_status("Success:#{head}")
    log "#{head}: DONE"
  end

  def restart_installation
    head = __method__
    log "#{head}: START"
    set_status("#{head}")
    for x in installation.frontends do
      job = DeployFrontendJob.get_job(x, "restart_remote_frontend")
      log "#{head}: restart_remote_frontend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.backends do
      job = DeployBackendJob.get_job(x, "restart_remote_backend")
      log "#{head}: restart_remote_backend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.endpoints do
      job = DeployEndpointJob.get_job(x, "restart_remote_endpoint")
      log "#{head}: restart_remote_endpoint #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    set_status("Success:#{head}")
    log "#{head}: DONE"
  end

  def stop_installation
    head = __method__
    log "#{head}: START"
    set_status("#{head}")
    for x in installation.frontends do
      job = DeployFrontendJob.get_job(x, "stop_remote_frontend")
      log "#{head}: stop_remote_frontend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.backends do
      job = DeployBackendJob.get_job(x, "stop_remote_backend")
      log "#{head}: stop_remote_backend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.endpoints do
      job = DeployEndpointJob.get_job(x, "stop_remote_endpoint")
      log "#{head}: stop_remote_endpoint #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    set_status("Success:#{head}")
    log "#{head}: DONE"
  end

  def status_installation
    head = __method__
    log "#{head}: START"
    set_status("#{head}")
    for x in installation.frontends do
      job = DeployFrontendJob.get_job(x, "status_remote_frontend")
      log "#{head}: status_remote_frontend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.backends do
      job = DeployBackendJob.get_job(x, "status_remote_backend")
      log "#{head}: status_remote_backend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.endpoints do
      job = DeployEndpointJob.get_job(x, "status_remote_endpoint")
      log "#{head}: status_remote_endpoint #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    set_status("Success:#{head}")
    log "#{head}: DONE"
  end

  def destroy_installation
    head = __method__
    log "#{head}: START"
    set_status("#{head}")
    if state.state_destroy
      if installation.frontends.count == 0 &&
        installation.backends.count == 0 &&
            installation.endpoints.count == 0
        log "#{head}: destroyed"
        installation.destroy
      else
        log "#{head}: reschedule  - frontends #{installation.frontends.count} backends #{installation.backends.count} endpoints #{installation.endpoints.count}"
        Delayed::Job.enqueue(self, :queue => "deploy-web")
      end
      return
    else
      state.state_destroy = true
      save
    end

    for x in installation.frontends do
      job = DeployFrontendJob.get_job(x, "destroy_remote_frontend")
      log "#{head}: destroy_remote_frontend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.backends do
      job = DeployBackendJob.get_job(x, "destroy_remote_backend")
      log "#{head}: destroy_remote_backend #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    for x in installation.endpoints do
      job = DeployEndpointJob.get_job(x, "destroy_remote_endpoint")
      log "#{head}: destroy_remote_endpoint #{x.name}"
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    log "#{head}: Intial Reschedule  - frontends #{installation.frontends.count} backends #{installation.backends.count} endpoints #{installation.endpoints.count}"
    Delayed::Job.enqueue(self, :queue => "deploy-web")
    set_status("Success:#{head}")
    log "#{head}: DONE"
  end


end