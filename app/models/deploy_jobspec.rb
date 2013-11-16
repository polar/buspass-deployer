class DeployJobspec < Struct.new(:job_id, :action, :name)

  def valid?(job)
    return false
  end

  def enqueue(job)
    job = DeployJob.find(job_id)
    if not valid?(job)
      return
    end
    job.log "Enqueued job to perform #{action} #{name}"
    job.set_status("Enqueued:#{action}")
  end

  def perform
    MongoMapper::Plugins::IdentityMap.clear
    job = DeployJob.find(job_id)
    if not valid?(job)
      return
    end
    job.send(action)
  end

  def error
    job = DeployJob.find(job_id)
    if not valid?(job)
      return
    end
    job.log "Error #{action} #{name}"
    job.set_status("Error:#{action}")
  end

  def failure
    job = DeployJob.find(job_id)
    if not valid?(job)
      return
    end
    job.log "Failure #{action} #{name}"
    job.set_status("Error:#{action}")
  end

end