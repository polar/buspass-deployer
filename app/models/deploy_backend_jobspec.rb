class DeployBackendJobspec < Struct.new(:deploy_backend_job_id, :name, :action, :endpoint_id)

  def enqueue(delayed_job)
    job = DeployBackendJob.find(deploy_backend_job_id)
    if job && job.backend.nil?
      puts "No backend"
      return
    end
    job.set_status("Enqueued:#{action}")
    job.log "Enqueued job to #{action} for #{job.backend.spec}"
  end

  def perform
    job = DeployBackendJob.find(deploy_backend_job_id)
    if job.nil?
      puts "No DeployBackendJob, exiting."
      return
    end

    case action
      when "create_swift_endpoint_apps"
        job.create_swift_endpoint_apps

      when "configure_swift_endpoint_apps"
        job.configure_swift_endpoint_apps

      when "start_swift_endpoint_apps"
        job.start_swift_endpoint_apps

      when "stop_swift_endpoint_apps"
        job.stop_swift_endpoint_apps

      when "deploy_swift_endpoint_apps"
        job.deploy_swift_endpoint_apps

      when "destroy_swift_endpoint_apps"
        job.destroy_swift_endpoint_apps

      when "destroy_swift_endpoints"
        job.destroy_swift_endpoints

      when "status_swift_endpoint_apps"
        job.status_swift_endpoint_apps
        
      when "create_worker_endpoint_apps"
        job.create_worker_endpoint_apps

      when "configure_worker_endpoint_apps"
        job.configure_worker_endpoint_apps

      when "start_worker_endpoint_apps"
        job.start_worker_endpoint_apps

      when "stop_worker_endpoint_apps"
        job.stop_worker_endpoint_apps

      when "deploy_worker_endpoint_apps"
        job.deploy_worker_endpoint_apps

      when "destroy_worker_endpoint_apps"
        job.destroy_worker_endpoint_apps

      when "destroy_worker_endpoints"
        job.destroy_worker_endpoints

      when "status_worker_endpoint_apps"
        job.status_worker_endpoint_apps

      when "destroy_backend"
        job.destroy_backend
      else
        job.log "Unknown action #{action}."
    end
  end
end
