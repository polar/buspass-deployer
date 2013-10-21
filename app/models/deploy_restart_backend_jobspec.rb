class DeployRestartBackendJobspec < Struct.new(:queue, :backend_id, :period)

  def enqueue(delayed_job)
    backend = Backend.find(backend_id)
    if backend
      puts "Backend #{backend.name} will be restarted every #{period} seconds."
    else
      puts "Backend not found"
    end
  end

  def perform
    MongoMapper::Plugins::IdentityMap.clear
    backend = Backend.find(backend_id)
    if backend
      @frontend = backend.frontend
      job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "restart_remote_backend", backend.id, backend.name)
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      Delayed::Job.enqueue(self, :queue => queue, :run_at => (Time.now + period.seconds))
    else
      puts "Backend not found"
    end
  end
end