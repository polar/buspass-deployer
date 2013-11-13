class DeployEndpointJobspec < Struct.new(:endpoint_job_id, :action, :name)

  def enqueue(job)
    job = DeployEndpointJob.find(endpoint_job_id)
    if job && job.endpoint.nil?
      puts "No endpoint"
      return
    end
    job.log "Enqueued job to perform #{action} #{job.endpoint.name}"
    job.set_status("Enqueued:#{action}")

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

  def error
    job = DeployEndpointJob.find(endpoint_job_id)
    if job && job.endpoint.nil?
      puts "No endpoint"
      return
    end
    job.log "Error #{action} #{job.endpoint.name}"
    job.set_status("Error:#{action}")
  end

  def failure
    job = DeployEndpointJob.find(endpoint_job_id)
    if job && job.endpoint.nil?
      puts "No endpoint"
      return
    end
    job.log "Failure #{action} #{job.endpoint.name}"
    job.set_status("Error:#{action}")
  end

end