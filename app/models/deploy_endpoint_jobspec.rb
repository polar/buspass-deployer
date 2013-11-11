class DeployEndpointJobspec < Struct.new(:endpoint_job_id, :action)

  def enqueue(job)
    job = DeployEndpointJob.find(endpoint_job_id)
    if job && job.endpoint.nil?
      puts "No endpoint"
      return
    end
    job.set_status("Enqueued:#{action}")
    job.log "Enqueued job to perform #{action} #{job.endpoint.name}"

  end

  def perform
    MongoMapper::Plugins::IdentityMap.clear
    job = DeployEndpointJob.find(endpoint_job_id)
    if job.nil?
      puts "No DeployEndpointJob, exiting."
      return
    end
    job.send(action)
  end

end