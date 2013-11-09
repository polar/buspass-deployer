class DeploySwiftEndpointJobspec < Struct.new(:endpoint_job_id, :name, :action)

  def enqueue(job)
    job = DeploySwiftEndpointJob.find(endpoint_job_id)
    if job && job.backend.nil?
      puts "No backend"
      return
    end
    job.set_status("Enqueued:#{action}")
    job.log "Enqueued job to perform #{action} #{job.backend.spec}"

  end

  def perform
    MongoMapper::Plugins::IdentityMap.clear
    job = DeployServerEndpointJob.find(endpoint_job_id)
    if job.nil?
      puts "No DeployServerEndpointJob, exiting."
      return
    end
    job.send(action)
  end

end