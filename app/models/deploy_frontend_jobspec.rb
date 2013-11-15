class DeployFrontendJobspec < Struct.new(:frontend_job_id, :action)

  def enqueue(delayed_job)
    job = DeployFrontendJob.find(frontend_job_id)
    if job.nil? || job.frontend.nil?
      puts "No Frontend"
      return
    end
    job.set_status("Enqueued:#{action}")
    job.log "Enqueued job to #{action} for frontend #{job.frontend.name}"
  end

  def perform
    MongoMapper::Plugins::IdentityMap.clear
    job = DeployFrontendJob.find(frontend_job_id)
    if job.nil? || job.frontend.nil?
      puts "No DeployFrontendJob, exiting."
      return
    end
    job.send(action)
  end

  def error
    job = DeployFrontendJob.find(frontend_job_id)
    if job.nil? || job.frontend.nil?
      puts "No endpoint"
      return
    end
    job.log "Error #{action} #{job.frontend.name}"
    job.set_status("Error:#{action}")
  end

  def failure
    job = DeployFrontendJob.find(frontend_job_id)
    if job.nil? || job.frontend.nil?
      puts "No endpoint"
      return
    end
    job.log "Failure #{action} #{job.frontend.name}"
    job.set_status("Error:#{action}")
  end
end
