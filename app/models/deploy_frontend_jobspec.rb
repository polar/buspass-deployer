class DeployFrontendJobspec < Struct.new(:deploy_frontend_job_id, :name, :action, :backend_id, :backend_name)

  def enqueue(delayed_job)
    job = DeployFrontendJob.find(deploy_frontend_job_id)
    if job && job.frontend.nil?
      puts "No frontend"
      return
    end
    job.set_status("Enqueued:#{action}")
    job.log "Enqueued job for #{action} for #{job.frontend.name}"
  end

  def perform
    job = DeployFrontendJob.find(deploy_frontend_job_id)
    if job.nil?
      puts "No DeployFrontendJob, exiting."
      return
    end
    case action
      when "install_remote_frontend"
        job.install_remote_frontend

      when "upgrade_remote_frontend"
        job.upgrade_remote_frontend

      when "full_upgrade_remote_frontend"
        job.full_upgrade_remote_frontend

      when "configure_remote_frontend"
        job.configure_remote_frontend

      when "configure_remote_frontend_backends"
        job.configure_remote_frontend_backends

      when "start_remote_frontend"
        job.start_remote_frontend

      when "stop_remote_frontend"
        job.stop_remote_frontend

      when "status_remote_frontend"
        job.status_remote_frontend

      when "deconfigure_remote_frontend"
        job.deconfigure_remote_frontend

      when "start_remote_backends"
        job.start_remote_backends

      when "stop_remote_backends"
        job.stop_remote_backends

      when "create_all_endpoint_apps"
        job.create_all_endpoint_apps
      when "configure_all_endpoint_apps"
        job.configure_all_endpoint_apps
      when "start_all_endpoint_apps"
        job.start_all_endpoint_apps
      when "restart_all_endpoint_apps"
        job.restart_all_endpoint_apps
      when "stop_all_endpoint_apps"
        job.stop_all_endpoint_apps
      when "deploy_all_endpoint_apps"
        job.deploy_all_endpoint_apps
      when "destroy_all_endpoint_apps"
        job.destroy_all_endpoint_apps

      when "configure_remote_backend"
        backend = Backend.find(backend_id)
        job.configure_remote_backend(backend)

      when "start_remote_backend"
        backend = Backend.find(backend_id)
        job.start_remote_backend(backend)

      when "stop_remote_backend"
        backend = Backend.find(backend_id)
        job.stop_remote_backend(backend)

      when "deconfigure_remote_backend"
        backend = Backend.find(backend_id)
        job.deconfigure_remote_backend(backend)

      when "destroy_frontend"
        job.destroy_frontend

      else
        job.log "Unknown action #{action}."
    end
  end
end
