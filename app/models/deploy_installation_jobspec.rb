class DeployInstallationJobspec < Struct.new(:installation_job_id, :action, :backend_id)

  def enqueue(delayed_job)
    job = DeployInstallationJob.find(installation_job_id)
    if job && job.installation.nil?
      puts "No Installation"
      return
    end
    job.set_status("Enqueued:#{action}")
    job.log "Enqueued job to #{action} for installation #{job.installation.name}"
  end

  def perform
    MongoMapper::Plugins::IdentityMap.clear
    job = DeployInstallationJob.find(installation_job_id)
    if job.nil?
      puts "No DeployInstallationJob, exiting."
      return
    end
    job.send(action, backend_id)
  end
end
