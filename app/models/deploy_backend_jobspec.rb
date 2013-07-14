class DeployBackendJobspec < Struct.new(:deploy_backend_job_id, :action, :swift_endpoint_id)

  def enqueue(delayed_job)
    job = DeployBackendJob.find(deploy_backend_job_id)
    if job && job.backend.nil?
      puts "No backend"
      return
    end
    job.delayed_job=(delayed_job)
    job.set_status("Enqueued")
    job.log "Enqueued job to #{action} for #{job.backend.spec}"
  end

  def perform
    job = DeployBackendJob.find(deploy_backend_job_id)
    if job.nil?
      puts "No DeployBackendJob, exiting."
      return
    end

    case action
      when "create_endpoint_apps"
        job.create_endpoint_apps

      when "configure_endpoint_apps"
        job.configure_endpoint_apps

      when "start_endpoint_apps"
        job.start_endpoint_apps

      when "deploy_endpoint_apps"
        job.deploy_endpoint_apps

      when "destroy_endpoint_apps"
        job.destroy_endpoint_apps

      when "status_endpoint_apps"
        job.status_endpoint_apps
      else
        job.log "Unknown action #{action}."
    end
  end
end
