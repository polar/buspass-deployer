class DeployServerEndpointJobspec < DeployEndpointJobspec

  def enqueue(job)
    job = DeployServerEndpointJob.find(endpoint_job_id)
    if  job.nil? ||  job.endpoint.nil?
      puts "No backend"
      return
    end
    job.log "Enqueued job to perform #{action} #{job.endpoint.name}"
    job.set_status("Enqueued:#{action}")
  end

  def perform
    MongoMapper::Plugins::IdentityMap.clear
    job = DeployServerEndpointJob.find(endpoint_job_id)
    if  job.nil? ||  job.endpoint.nil?
      puts "No DeployServerEndpointJob, exiting."
      return
    end
    job.send(action)
  end
  def error
    job = DeployServerEndpointJob.find(endpoint_job_id)
    if  job.nil? ||  job.endpoint.nil?
      puts "No endpoint"
      return
    end
    job.log "Error #{action} #{job.endpoint.name}"
    job.set_status("Error:#{action}")
  end

  def failure
    job = DeployServerEndpointJob.find(endpoint_job_id)
    if  job.nil? ||  job.endpoint.nil?
      puts "No endpoint"
      return
    end
    job.log "Failure #{action} #{job.endpoint.name}"
    job.set_status("Error:#{action}")
  end

end