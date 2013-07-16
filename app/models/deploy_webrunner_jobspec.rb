class DeployWebrunnerJobspec < Struct.new(:deploy_webrunner_job_id, :action)

  def enqueue(delayed_job)
    job = DeployWebrunnerJob.find(deploy_webrunner_job_id)
    if job && job.backend.nil?
      puts "No backend"
      return
    end
    job.delayed_job=(delayed_job)
    job.set_status("Enqueued")
    job.log "Enqueued job to create a web runner for #{job.backend.spec}"
  end

  def perform
    job = DeployWebrunnerJob.find(deploy_webrunner_job_id)
    if job.nil?
      puts "No DeployWebRunnerJob, exiting."
      return
    end
    case action
      when "create"
        job.reset_api
        job.create_remote_runner
      when "configure"
        job.reset_api
        job.configure_remote_runner
      when "deploy"
        job.reset_api
        job.deploy_remote_runner
      when "destroy"
        job.reset_api
        job.destroy_remote_runner
      when "job_create_and_deploy_remote_runner"
        job.reset_api
        job.job_create_and_deploy_remote_runner
      else
        job.log "Unknown action : #{action}."
    end
  end
end