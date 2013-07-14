class DeployBackendJob
  include MongoMapper::Document

  belongs_to :delayed_job, :class_name => "Delayed::Job", :dependent => :destroy
  belongs_to :backend

  key :status_content

  attr_accessible :backend, :backend_id

  def set_status(s)
    begin
      reload
    rescue
    end
    self.status_content = s
    save
    log("status: #{s}")
  end

  def get_status
    status_content
  end

  def log(s)
    backend.log(s)
  end

  def to_a()
    reload
    log_content
  end

  def segment(i, n)
    log_content.drop(i).take(n)
  end

  def host
    backend.host
  end

  def port
    backend.port
  end

  def frontend
    backend.frontend
  end

  def create_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Creating Endpoint Apps #{backend.name}."
    for se in backend.swift_endpoints do
      begin
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Creating Remote App for #{se.name}."
        se.deploy_swift_endpoint_job.create_remote_endpoint
      rescue Exception => boom
        log "#{head}: Error creating Endpoint #{se.name} - #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def configure_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Configuring Endpoint Apps #{backend.name}."
    for se in backend.swift_endpoints do
      begin
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Configuring Remote App for #{se.name}."
        se.deploy_swift_endpoint_job.configure_remote_endpoint
      rescue Exception => boom
        log "#{head}: Cannot configure endpoint #{se.name} - #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def deploy_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Deploying Endpoint Apps for #{backend.name}."
    for se in backend.swift_endpoints do
      begin
          if se.deploy_swift_endpoint_job.nil?
            se.create_deploy_swift_endpoint_job
          end
          log "#{head}: Deploying Remote App for #{se.name}."
          if ! se.deploy_swift_endpoint_job.remote_endpoint_exists?
            log "#{head}: Endpoint #{se.name} does not exist. Creating."
            se.deploy_swift_endpoint_job.create_remote_endpoint
          end
          se.deploy_swift_endpoint_job.deploy_to_remote_endpoint
      rescue Exception => boom
        log "#{head}: Error Deploying Endpoint #{se.name} - #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def start_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Start Endpoint Apps #{backend.name}."
    for se in backend.swift_endpoints do
      begin
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Starting Remote App for #{se.name}."
        se.deploy_swift_endpoint_job.start_remote_endpoint
      rescue Exception => boom
        log "#{head}: Cannot start endpoint #{se.name} - #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def stop_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Stop Endpoint Apps #{backend.name}."
    for se in backend.swift_endpoints do
      begin
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Stopping Remote App for #{se.name}."
        se.deploy_swift_endpoint_job.stop_remote_endpoint
      rescue Exception => boom
        log "#{head}: Cannot stop endpoint #{se.name} - #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def destroy_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Destroying Endpoint Apps #{backend.name}."
    for se in backend.swift_endpoints do
      begin
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Destroying Remote App for #{se.name}."
        se.deploy_swift_endpoint_job.destroy_remote_endpoint
      rescue Exception => boom
        log "#{head}: Cannot destroy endpoint #{se.name} - #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

  def status_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Status Endpoint Apps #{backend.name}."
    for se in backend.swift_endpoints do
      begin
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Status Remote App for #{se.name}."
        se.deploy_swift_endpoint_job.remote_endpoint_status
      rescue Exception => boom
        log "#{head}: Cannot get status endpoint #{se.name} - #{boom}"
      end
    end
  ensure
    log "#{head}: DONE"
  end

end