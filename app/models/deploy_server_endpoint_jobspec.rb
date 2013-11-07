class DeployServerEndpointJobspec < Struct.new(:deploy_server_endpoint_job_id, :name, :action)

  def enqueue(delayed_job)
    job = DeployServerEndpointJob.find(deploy_server_endpoint_job_id)
    if job && job.backend.nil?
      puts "No backend"
      return
    end
    job.set_status("Enqueued:#{action}")
    job.log "Enqueued job to perform #{action} #{job.backend.spec}"
  end

  def perform
    MongoMapper::Plugins::IdentityMap.clear
    job = DeployServerEndpointJob.find(deploy_server_endpoint_job_id)
    if job.nil?
      puts "No DeployServerEndpointJob, exiting."
      return
    end
    case action
      when "create"
        job.reset_api
        job.create_remote_endpoint
      when "configure"
        job.reset_api
        job.configure_remote_endpoint
      when "deploy"
        job.reset_api
        job.deploy_remote_endpoint
      when "destroy"
        job.reset_api
        job.destroy_remote_endpoint

      when "job_create_and_deploy_remote_endpoint"
        job.reset_api
        job.job_create_and_deploy_remote_endpoint

      when "create_remote_endpoint"
        job.reset_api
        job.create_remote_endpoint

      when "remote_endpoint_exists?"
        job.reset_api
        job.remote_endpoint_exists?

      when "remote_endpoint_status"
        job.reset_api
        job.remote_endpoint_status

      when "start_remote_endpoint"
        job.reset_api
        job.start_remote_endpoint

      when "restart_remote_endpoint"
        job.reset_api
        job.restart_remote_endpoint

      when "stop_remote_endpoint"
        job.reset_api
        job.stop_remote_endpoint

      when "configure_remote_endpoint"
        job.reset_api
        job.configure_remote_endpoint

      when "deploy_to_remote_endpoint"
        job.reset_api
        job.deploy_to_remote_endpoint

      when "destroy_remote_endpoint"
        job.reset_api
        job.destroy_remote_endpoint

      when "destroy_server_endpoint"
        job.reset_api
        job.destroy_server_endpoint

      when "logs_remote_endpoint"
        job.reset_api
        job.logs_remote_endpoint

      when "truncate_logs_remote_endpoint"
        job.reset_api
        job.truncate_logs_remote_endpoint

      else
        job.log "Unknown action : #{action}."
    end
  end
end