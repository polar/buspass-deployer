# This is the implementation of a Delayed::Job struct.
class DeployCreateWorkerEndpointJobspec < Struct.new(:endpoint_id, :endpoint_name)

  def perform
    puts "Attempting to create remote entity for Worker Endpoint '#{endpoint_name}'"
    endpoint = WorkerEndpoint.find(endpoint_id)
    if endpoint
      if endpoint.deployment_type.nil? || endpoint.deployment_type.blank?
        endpoint.deployment_type = "Heroku"
        endpoint.save
      end
      # jopspec has the newly created job id.
      begin
        jobspec = DeployEndpointJob.get_job(endpoint, "create_remote_endpoint")
        jobspec.perform
        jobspec = DeployEndpointJob.get_job(endpoint, "configure_remote_endpoint")
        jobspec.perform
        jobspec = DeployEndpointJob.get_job(endpoint, "deploy_to_remote_endpoint")
        jobspec.perform
        jobspec = DeployEndpointJob.get_job(endpoint, "start_remote_endpoint")
        jobspec.perform
      rescue Exception => boom
        begin
          puts "Problem creating and deploying to Worker Endpoint #{endpoint.name}: #{boom}"
          puts "#{boom.backtrace.inspect}"
          jobspec = DeployEndpointJob.get_job(endpoint, "destroy_remote_endpoint")
          jobspec.perform
        rescue Exception => boom2
          puts "Problem destroying Worker Endpoint #{endpoint.name} after problem creating it. #{boom2}"
        end
      end
    else
      puts "Attempt to create endpoint '#{endpoint_name}' that doesn't exist."
    end
  end
end