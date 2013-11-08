class DeployWorkerEndpoint1Jobspec < Struct.new(:endpoint_job_id, :name, :action)

  def enqueue(job)
    job = DeployWorkerEndpointJob.find(endpoint_job_id)
    if job && job.backend.nil?
      puts "No backend"
      return
    end
    job.set_status("Enqueued:#{action}")
    job.log "Enqueued job to perform #{action} #{job.backend.spec}"
  end

  def perform
    MongoMapper::Plugins::IdentityMap.clear
    job = DeployWorkerEndpoint1Job.find(endpoint_job_id)
    if job.nil?
      puts "No DeployWorkerEndpointJob, exiting."
      return
    end
    job.send(action)
  end

end