class DeployBackend1Jobspec < Struct.new(:backend_job_id, :name, :action)

  def enqueue(job)
    job = DeployBackend1Job.find(backend_job_id)
    if job && job.backend.nil?
      puts "No backend"
      return
    end
    job.set_status("Enqueued:#{action}")
    job.log "Enqueued job to perform #{action}"
  end

  def perform
    MongoMapper::Plugins::IdentityMap.clear
    job = DeployBackend1Job.find(backend_job_id)
    if job.nil?
      puts "No DeployBackend1Job, exiting."
      return
    end
    job.send(action)
  end

end