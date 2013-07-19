class DeployBackendJob
  include MongoMapper::Document

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

  def create_swift_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Creating Swift Endpoint Apps #{backend.name}."
    set_status("CreatingSwiftEndpoints")
    errors = 0
    for se in backend.swift_endpoints do
      begin
        set_status("CreatingSwiftEndpoints:#{se.name}")
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Creating Remote App for Swift Endpoint #{se.name}."
        se.deploy_swift_endpoint_job.create_remote_endpoint
      rescue Exception => boom
        set_status("Error:CreateSwiftEndpoints:#{se.name}")
        errors += 1
        log "#{head}: Error creating Swift Endpoint #{se.name} - #{boom}"
      end
    end
    if errors == 0
      set_status("Success:CreateSwiftEndpoints")
    else
      set_status("Error:CreateSwiftEndpoints:#{errors}")
    end
  ensure
    log "#{head}: DONE"
  end

  def configure_swift_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Configuring Swift Endpoint Apps #{backend.name}."
    set_status("ConfiguringSwiftEndpoints")
    errors = 0
    for se in backend.swift_endpoints do
      begin
        set_status("ConfiguringSwiftEndpoints:#{se.name}")
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Configuring Remote App for Swift Endpoint #{se.name}."
        job = DeploySwiftEndpointJobspec.new(se.deploy_swift_endpoint_job.id, "configure_remote_endpoint")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        set_status("Success:ConfiguringSwiftEndpoints:#{se.name}")
      rescue Exception => boom
        errors += 1
        set_status("Error:ConfiguringSwiftEndpoints:#{se.name}")
        log "#{head}: Cannot configure Swift Endpoint #{se.name} - #{boom}"
      end
    end
    if errors == 0
      set_status("Success:ConfiguringSwiftEndpoints")
    else
      set_status("Error:ConfiguringSwiftEndpoints:#{errors}")
    end
  ensure
    log "#{head}: DONE"
  end

  def deploy_swift_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Deploying Swift Endpoint Apps for #{backend.name}."
    set_status("DeployingSwiftEndpoints")
    for se in backend.swift_endpoints do
      begin
          if se.deploy_swift_endpoint_job.nil?
            se.create_deploy_swift_endpoint_job
          end
          log "#{head}: Deploying Remote App for Swift Endpoint #{se.name}."
          job = DeploySwiftEndpointJobspec.new(se.deploy_swift_endpoint_job.id, "job_create_and_deploy_remote_endpoint")
          Delayed::Job.enqueue(job, :queue => "deploy-web")
      rescue Exception => boom
        set_status("Error:DeployingSwiftEndpoints")
        log "#{head}: Error Deploying Swift Endpoint #{se.name} - #{boom}"
      end
      set_status("Success:DeployingSwiftEndpoints")
    end
  ensure
    log "#{head}: DONE"
  end

  def start_swift_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Start Swift Endpoint Apps #{backend.name}."
    set_status("StartingSwiftEndpoints")
    errors = 0
    for se in backend.swift_endpoints do
      begin
        set_status("StartSwiftEndpoints:#{se.name}")
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Starting Remote App for Swift Endpoint #{se.name}."
        job = DeploySwiftEndpointJobspec.new(se.deploy_swift_endpoint_job.id, "start_remote_endpoint")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        set_status("Success:StartSwiftEndpoints:#{se.name}")
      rescue Exception => boom
        errors += 1
        set_status("Error:StartSwiftEndpoints:#{se.name}")
        log "#{head}: Cannot start Swift Endpoint #{se.name} - #{boom}"
      end
    end
    if errors == 0
      set_status("Success:StartSwiftEndpoints")
    else
      set_status("Error:StartSwiftEndpoints:#{errors}")
    end
  ensure
    log "#{head}: DONE"
  end

  def stop_swift_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Stop Swift Endpoint Apps #{backend.name}."
    set_status("StoppingSwiftEndpoints")
    errors = 0
    for se in backend.swift_endpoints do
      begin
        set_status("StartingSwiftEndpoints:#{se.name}")
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Stopping Remote App for Swift Endpoint #{se.name}."
        job = DeploySwiftEndpointJobspec.new(se.deploy_swift_endpoint_job.id, "stop_remote_endpoint")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        set_status("Success:StartSwiftEndpoints:#{se.name}")
      rescue Exception => boom
        set_status("Error:StartSwiftEndpoints:#{se.name}")
        errors += 1
        log "#{head}: Cannot stop Swift Endpoint #{se.name} - #{boom}"
      end
    end
    if errors == 0
      set_status("Success:StartSwiftEndpoints")
    else
      set_status("Error:StartSwiftEndpoints:#{errors}")
    end
  ensure
    log "#{head}: DONE"
  end

  def destroy_swift_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Destroying Swift Endpoint Apps #{backend.name}."
    set_status("DestroyingSwiftEndpoints")
    errors = 0
    for se in backend.swift_endpoints do
      begin
        set_status("DestroyingSwiftEndpoints:#{se.name}")
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Destroying Remote App for Swift Endpoint #{se.name}."
        job = DeploySwiftEndpointJobspec.new(se.deploy_swift_endpoint_job.id, "destroy_remote_endpoint")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        set_status("Success:DestroySwiftEndpoints:#{se.name}")
      rescue Exception => boom
        set_status("Error:DestroySwiftEndpoints:#{se.name}")
        errors += 1
        log "#{head}: Cannot destroy Swift Endpoint #{se.name} - #{boom}"
      end
    end
    if errors == 0
      set_status("Success:DestroySwiftEndpoints")
    else
      set_status("Error:DestroySwiftEndpoints:#{errors}")
    end
  ensure
    log "#{head}: DONE"
  end

  def status_swift_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Status Swift Endpoint Apps #{backend.name}."
    set_status("RemoteStatus:Swift")
    for se in backend.swift_endpoints do
      begin
        if se.deploy_swift_endpoint_job.nil?
          se.create_deploy_swift_endpoint_job
        end
        log "#{head}: Status Remote App for Swift Endpoint #{se.name}."
        job = DeploySwiftEndpointJobspec.new(se.deploy_swift_endpoint_job.id, "remote_endpoint_status")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
      rescue Exception => boom
        log "#{head}: Cannot get status Swift Endpoint #{se.name} - #{boom}"
      end
    end
    set_status("Done:RemoteStatus:Swift")
  ensure
    log "#{head}: DONE"
  end

  def create_worker_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Creating Worker Endpoint Apps #{backend.name}."
    set_status("CreatingWorkerEndpoints")
    errors = 0
    for se in backend.worker_endpoints do
      begin
        set_status("CreatingWorkerEndpoints:#{se.name}")
        if se.deploy_worker_endpoint_job.nil?
          se.create_deploy_worker_endpoint_job
        end
        log "#{head}: Creating Remote App for Worker Endpoint #{se.name}."
        job = DeployWorkerEndpointJobspec.new(se.deploy_worker_endpoint_job.id, "create_remote_endpoint")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        set_status("Success:CreateWorkerEndpoints:#{se.name}")
      rescue Exception => boom
        set_status("Error:CreateWorkerEndpoints:#{se.name}")
        errors += 1
        log "#{head}: Error creating Worker Endpoint #{se.name} - #{boom}"
      end
    end
    if errors == 0
      set_status("Success:CreateWorkerEndpoints")
    else
      set_status("Error:CreateWorkerEndpoints:#{errors}")
    end
  ensure
    log "#{head}: DONE"
  end

  def configure_worker_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Configuring Worker Endpoint Apps #{backend.name}."
    set_status("ConfiguringWorkerEndpoints")
    errors = 0
    for se in backend.worker_endpoints do
      begin
        set_status("ConfiguringWorkerEndpoints:#{se.name}")
        if se.deploy_worker_endpoint_job.nil?
          se.create_deploy_worker_endpoint_job
        end
        log "#{head}: Configuring Remote App for Worker Endpoint #{se.name}."
        job = DeployWorkerEndpointJobspec.new(se.deploy_worker_endpoint_job.id, "configure_remote_endpoint")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        set_status("Success:ConfigureWorkerEndpoints:#{se.name}")
      rescue Exception => boom
        set_status("Error:ConfigureWorkerEndpoints:#{se.name}")
        errors += 1
        log "#{head}: Cannot configure Worker Endpoint #{se.name} - #{boom}"
      end
    end
    if errors == 0
      set_status("Success:ConfigureWorkerEndpoints")
    else
      set_status("Error:ConfigureWorkerEndpoints:#{errors}")
    end
  ensure
    log "#{head}: DONE"
  end

  def deploy_worker_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Deploying Worker Endpoint Apps for #{backend.name}."
    set_status("DeployingWorkerEndpoints")
    errors = 0
    for se in backend.worker_endpoints do
      begin
        set_status("DeployingWorkerEndpoints:#{se.name}")
        if se.deploy_worker_endpoint_job.nil?
          se.create_deploy_worker_endpoint_job
        end
        log "#{head}: Deploying Remote App for Worker Endpoint #{se.name}."
        job = DeployWorkerEndpointJobspec.new(se.deploy_worker_endpoint_job.id, "job_create_and_deploy_remote_endpoint")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        set_status("Success:DeployWorkerEndpoints:#{se.name}")
      rescue Exception => boom
        set_status("Error:DeployWorkerEndpoints:#{se.name}")
        errors += 1
        log "#{head}: Error Deploying Worker Endpoint #{se.name} - #{boom}"
      end
    end
    if errors == 0
      set_status("Success:ConfigureWorkerEndpoints")
    else
      set_status("Error:ConfigureWorkerEndpoints:#{errors}")
    end
  ensure
    log "#{head}: DONE"
  end

  def start_worker_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Start Worker Endpoint Apps #{backend.name}."
    set_status("StartingWorkerEndpoints")
    errors = 0
    for se in backend.worker_endpoints do
      begin
        set_status("StartingWorkerEndpoints:#{se.name}")
        if se.deploy_worker_endpoint_job.nil?
          se.create_deploy_worker_endpoint_job
        end
        log "#{head}: Starting Remote App for Worker Endpoint #{se.name}."
        job = DeployWorkerEndpointJobspec.new(se.deploy_worker_endpoint_job.id, "start_remote_endpoint")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        set_status("Success:StartWorkerEndpoints:#{se.name}")
      rescue Exception => boom
        set_status("Error:StartWorkerEndpoints:#{se.name}")
        errors += 1
        log "#{head}: Cannot start Worker Endpoint #{se.name} - #{boom}"
      end
    end
    if errors == 0
      set_status("Success:StartWorkerEndpoints")
    else
      set_status("Error:StartWorkerEndpoints:#{errors}")
    end
  ensure
    log "#{head}: DONE"
  end

  def stop_worker_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Stop Worker Endpoint Apps #{backend.name}."
    set_status("StopWorkerEndpoints")
    errors = 0
    for se in backend.worker_endpoints do
      begin
        set_status("StopingWorkerEndpoints:#{se.name}")
        if se.deploy_worker_endpoint_job.nil?
          se.create_deploy_worker_endpoint_job
        end
        log "#{head}: Stopping Remote App for Worker Endpoint #{se.name}."
        job = DeployWorkerEndpointJobspec.new(se.deploy_worker_endpoint_job.id, "stop_remote_endpoint")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        set_status("Success:StopWorkerEndpoints:#{se.name}")
      rescue Exception => boom
        set_status("Error:StopWorkerEndpoints:#{se.name}")
        errors += 1
        log "#{head}: Cannot stop Worker Endpoint #{se.name} - #{boom}"
      end
    end
    if errors == 0
      set_status("Success:StopWorkerEndpoints")
    else
      set_status("Error:StopWorkerEndpoints:#{errors}")
    end
  ensure
    log "#{head}: DONE"
  end

  def destroy_worker_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Destroying Worker Endpoint Apps #{backend.name}."
    set_status("DestroyingWorkerEndpoints")
    errors = 0
    for se in backend.worker_endpoints do
      begin
        set_status("DestroyingWorkerEndpoints:#{se.name}")
        if se.deploy_worker_endpoint_job.nil?
          se.create_deploy_worker_endpoint_job
        end
        log "#{head}: Destroying Remote App for Worker Endpoint #{se.name}."
        job = DeployWorkerEndpointJobspec.new(se.deploy_worker_endpoint_job.id, "destroy_remote_endpoint")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        set_status("Success:DestroyWorkerEndpoints:#{se.name}")
      rescue Exception => boom
        set_status("Error:DestroyWorkerEndpoints:#{se.name}")
        errors += 1
        log "#{head}: Cannot destroy Worker Endpoint #{se.name} - #{boom}"
      end
    end
    if errors == 0
      set_status("Success:DestroyWorkerEndpoints")
    else
      set_status("Error:DestroyWorkerEndpoints:#{errors}")
    end
  ensure
    log "#{head}: DONE"
  end

  def status_worker_endpoint_apps
    head = __method__
    log "#{head}: START"
    log "#{head}: Status Worker Endpoint Apps #{backend.name}."
    set_status("RemoteStatus:Worker")
    for se in backend.worker_endpoints do
      begin
        if se.deploy_worker_endpoint_job.nil?
          se.create_deploy_worker_endpoint_job
        end
        log "#{head}: Status Remote App for Worker Endpoint #{se.name}."
        job = DeployWorkerEndpointJobspec.new(se.deploy_worker_endpoint_job.id, "remote_endpoint_status")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
      rescue Exception => boom
        log "#{head}: Cannot get status Worker Endpoint #{se.name} - #{boom}"
      end
    end
    set_status("Done:RemoteStatus:Worker")
  ensure
    log "#{head}: DONE"
  end

end