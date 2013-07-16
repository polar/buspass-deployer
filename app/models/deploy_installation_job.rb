class DeployInstallationJob
  include MongoMapper::Document

  one :installation

  key :status_content

  attr_accessible :installation, :installation_id

  def set_status(s)
    self.status_content = s
    save
    log("status: #{s}")
  end

  def get_status
    status_content
  end

  def log(s)
    installation.log(s)
  end

  def to_a()
    reload
    log_content
  end

  def segment(i, n)
    log_content.drop(i).take(n)
  end

  def null_all_statuses
    set_status(nil)
    installation.installation_log.clear
    for fe in installation.frontends do
      if fe.deploy_frontend_job.nil?
        fe.create_deploy_frontend_job
      end
      fe.deploy_frontend_job.set_status(nil)
      fe.frontend_log.clear
    end
    for fe in installation.backends do
      if fe.deploy_backend_job.nil?
        fe.create_deploy_backend_job
      end
      fe.deploy_backend_job.set_status(nil)
      fe.backend_log.clear
    end
    for fe in installation.swift_endpoints do
      if fe.deploy_swift_endpoint_job.nil?
        fe.create_deploy_swift_endpoint_job
      end
      fe.deploy_swift_endpoint_job.set_status(nil)
      fe.swift_endpoint_log.clear
    end
    for fe in installation.worker_endpoints do
      if fe.deploy_worker_endpoint_job.nil?
        fe.create_deploy_worker_endpoint_job
      end
      fe.deploy_worker_endpoint_job.set_status(nil)
      fe.worker_endpoint_log.clear
    end
  end

  def install_frontends
    head = __method__
    log "#{head}: START"
    for fe in installation.frontends do
      if fe.deploy_frontend_job.nil?
        fe.create_deploy_frontend_job
      end
      begin
        log "#{head}: Installing frontend #{fe.name}"
        fe.deploy_frontend_job.install_remote_frontend
      rescue Exception => boom
        log "#{head}: Error in installing frontend #{fe.name} -- #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def upgrade_frontends
    head = __method__
    log "#{head}: START"
    for fe in @installation.frontends do
      if fe.deploy_frontend_job.nil?
        fe.create_deploy_frontend_job
      end
      begin
        fe.deploy_frontend_job.upgrade_remote_frontend
      rescue Exception => boom
        log "#{head}: Error in installing frontend #{fe.name} -- #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def configure_frontends
    head = __method__
    log "#{head}: START"
    for fe in @installation.frontends do
      if fe.deploy_frontend_job.nil?
        fe.create_deploy_frontend_job
      end
      begin
        fe.deploy_frontend_job.configure_remote_frontend
      rescue Exception => boom
        log "#{head}: Error in installing frontend #{frontend.name} -- #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def deconfigure_frontends
    head = __method__
    log "#{head}: START"
    for fe in @installation.frontends do
      if fe.deploy_frontend_job.nil?
        fe.create_deploy_frontend_job
      end
      begin
        fe.deploy_frontend_job.deconfigure_remote_frontend
      rescue Exception => boom
        log "#{head}: Error in installing frontend #{fe.name} -- #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def start_frontends
    head = __method__
    log "#{head}: START"
    for fe in @installation.frontends do
      if fe.deploy_frontend_job.nil?
        fe.create_deploy_frontend_job
      end
      begin
        fe.deploy_frontend_job.start_remote_frontend
      rescue Exception => boom
        log "#{head}: Error in installing frontend #{fe.name} -- #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def stop_frontends
    head = __method__
    log "#{head}: START"
    for fe in @installation.frontends do
      if fe.deploy_frontend_job.nil?
        fe.create_deploy_frontend_job
      end
      begin
        fe.deploy_frontend_job.stop_remote_frontend
      rescue Exception => boom
        log "#{head}: Error in installing frontend #{fe.name} -- #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def upgrade_installation
    head = __method__
    log "#{head}: START"
    set_status("UpgradeInstallation:Frontends:#{installation.frontends.count}")
    for fe in installation.frontends do
      if fe.deploy_frontend_job.nil?
        fe.create_deploy_frontend_job
      end
      begin
        log "#{head}: stop_remote_frontend #{fe.name}"
        fe.deploy_frontend_job.stop_remote_frontend
        log "#{head}: upgrade_remote_frontend #{fe.name}"
        job = DeployFrontendJobspec.new(fe.deploy_frontend_job.id, "upgrade_remote_frontend", nil)
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        #fe.deploy_frontend_job.upgrade_remote_frontend
      rescue Exception => boom
        log "#{head}: Error in installing frontend #{fe.name} -- #{boom}"
      end
    end
    backends = installation.backends
    set_status("UpgradeInstallation:Backends:#{backends.count}")
    for be in backends do
      if be.deploy_backend_job.nil?
        be.create_deploy_backend_job
      end
      begin
        if ! be.configured
          log "#{head}: configure_remote_backend #{be.name}"
          be.deploy_backend_job.configure_remote_backend
        end
        log "#{head}: deploy_swift_endpoint_apps #{be.name}"
        job = DeployBackendJobspec.new(be.deploy_backend_job.id, "deploy_swift_endpoint_apps", nil)
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        #be.deploy_backend_job.deploy_swift_endpoint_apps
        log "#{head}: deploy_worker_endpoint_apps #{be.name}"
        job = DeployBackendJobspec.new(be.deploy_backend_job.id, "deploy_worker_endpoint_apps", nil)
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        #be.deploy_backend_job.deploy_worker_endpoint_apps
      rescue Exception => boom
        log "#{head}: Error in deploying backend #{be.name} -- #{boom}"
      end
    end
    set_status("Done:UpgradeInstallation")
  ensure
    log "#{head}: DONE"
  end

  def start_installation
    head = __method__
    log "#{head}: START"
    for fe in installation.frontends do
      if fe.deploy_frontend_job.nil?
        fe.create_deploy_frontend_job
      end
      begin
        log "#{head}: start_remote_frontend #{fe.name}"
        fe.deploy_frontend_job.start_remote_frontend
      rescue Exception => boom
        log "#{head}: Error in starting frontend #{fe.name} -- #{boom}"
      end
    end
    for be in installation.backends do
      if be.deploy_backend_job.nil?
        be.create_deploy_backend_job
      end
      begin
        if ! be.configured
          be.deploy_backend_job.configure_remote_backend
        end
        log "#{head}: start_remote_backend #{be.name}"
        be.deploy_backend_job.start_remote_backend
      rescue Exception => boom
        log "#{head}: Error in starting backend #{be.name} -- #{boom}"
      end
    end
    for be in installation.backends do
      begin
        log "#{head}: start_swift_endpoint_apps #{be.name}"
        be.deploy_backend_job.start_swift_endpoint_apps
        log "#{head}: start_worker_endpoint_apps #{be.name}"
        be.deploy_backend_job.start_worker_endpoint_apps
      rescue Exception => boom
        log "#{head}: Error in starting backend #{be.name} -- #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def stop_installation
    head = __method__
    log "#{head}: START"
    for fe in installation.frontends do
      if fe.deploy_frontend_job.nil?
        fe.create_deploy_frontend_job
      end
      begin
        log "#{head}: stop_remote_frontend #{fe.name}"
        fe.deploy_frontend_job.stop_remote_frontend
      rescue Exception => boom
        log "#{head}: Error in starting frontend #{fe.name} -- #{boom}"
      end
    end
    for be in installation.backends do
      if be.deploy_backend_job.nil?
        be.create_deploy_backend_job
      end
      begin
        if ! be.configured
          log "#{head}: configure_remote_backend #{be.name}"
          be.deploy_backend_job.configure_remote_backend
        end
        log "#{head}: stop_remote_backend #{be.name}"
        be.deploy_backend_job.stop_remote_backend
        log "#{head}: stop_swift_endpoint_apps #{be.name}"
        be.deploy_backend_job.stop_swift_endpoint_apps
        log "#{head}: stop_worker_endpoint_apps #{be.name}"
        be.deploy_backend_job.stop_worker_endpoint_apps
      rescue Exception => boom
        log "#{head}: Error in starting backend #{be.name} -- #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def restart_swift_endpoints
    head = __method__
    log "#{head}: START"
    for se in installation.swift_endpoints do
      begin
        log "#{head}: Restarting Swift Endpoint #{se.name}"
        se.deploy_swift_endpoint_job.restart_remote_endpoint
      rescue Exception => boom
        log "#{head}: Error in Swift Endpoint #{se.name} -- #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def restart_worker_endpoints
    head = __method__
    log "#{head}: START"
    for se in installation.worker_endpoints do
      begin
        log "#{head}: Restarting Worker Endpoint #{se.name}"
        se.deploy_worker_endpoint_job.restart_remote_endpoint
      rescue Exception => boom
        log "#{head}: Error in starting Worker Endpoint #{se.name} -- #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

end