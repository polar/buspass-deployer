class DeployInstallationJobspec < Struct.new(:deploy_installation_job_id, :action, :backend_id)

  def enqueue(delayed_job)
    job = DeployInstallationJob.find(deploy_installation_job_id)
    if job && job.installation.nil?
      puts "No Installation"
      return
    end
    job.set_status("Enqueued:#{action}")
    job.log "Enqueued job to #{action} for installation #{job.installation.name}"
  end

  def perform
    job = DeployInstallationJob.find(deploy_installation_job_id)
    if job.nil?
      puts "No DeployInstallationJob, exiting."
      return
    end
    case action
      when "install_frontends"
        job.install_frontends

      when "upgrade_frontends"
        job.upgrade_frontends

      when "configure_frontends"
        job.configure_frontends

      when "deconfigure_frontends"
        job.deconfigure_frontends

      when "start_frontends"
        job.start_frontends

      when "stop_frontends"
        job.stop_frontends

      when "upgrade_installation"
        job.upgrade_installation

      when "start_installation"
        job.start_installation

      when "stop_installation"
        job.stop_installation

      when "restart_swift_endpoints"
        job.restart_swift_endpoints

      when "restart_worker_endpoints"
        job.restart_worker_endpoints

      when "remote_status_installation"
        job.remote_status_installation
      else
        job.log "Unknown action #{action}."
    end
  end
end
