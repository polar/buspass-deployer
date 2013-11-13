class DeployInstallationJobspec < Struct.new(:installation_job_id, :action, :backend_id)

  def enqueue(delayed_job)
    job = DeployInstallationJob.find(installation_job_id)
    if job.nil? || job.installation.nil?
      puts "No Installation"
      return
    end
    job.set_status("Enqueued:#{action}")
    job.log "Enqueued job to #{action} for installation #{job.installation.name}"
  end

  def perform
    MongoMapper::Plugins::IdentityMap.clear
    job = DeployInstallationJob.find(installation_job_id)
    if job.nil? || job.installation.nil?
      puts "No DeployInstallationJob, exiting."
      return
    end
    job.send(action, backend_id)
  end

  def error
    job = DeployInstallationJob.find(installation_job_id)
    if job.nil? || job.installation.nil?
      puts "No endpoint"
      return
    end
    job.log "Error #{action} #{job.installation.name}"
    job.set_status("Error:#{action}")
  end

  def failure
    job = DeployInstallationJob.find(installation_job_id)
    if job.nil? || job.installation.nil?
      puts "No endpoint"
      return
    end
    job.log "Failure #{action} #{job.installation.name}"
    job.set_status("Error:#{action}")
  end
end
