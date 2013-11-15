class DeployEndpointJob < DeployJob

  def delayed_jobs
    Delayed::Job.where(:queue => "deploy-web").reduce([]) do |result, x|
      if x.payload_object.is_a?(DeployEndpointJobspec) && x.payload_object.endpoint_job_id == self.id
        result + [x]
      else
        result
      end
    end
  end

  def backend
    endpoint.backend
  end

  def frontend
    backend.frontend
  end

  def installation
    frontend.installation
  end

  def endpoint_log
    state.endpoint_log
  end

  def git_commit
    state.git_commit
  end

  def status
    status_content
  end

  def remote_status
    state.remote_status
  end

  def instance_status
    state.instance_status
  end

  def create_remote_endpoint
    load_impl
    self.send(__method__)
  end

  def configure_remote_endpoint
    load_impl
    self.send(__method__)
  end

  def deploy_to_remote_endpoint
    load_impl
    self.send(__method__)
  end

  def start_remote_endpoint
    load_impl
    self.send(__method__)
  end

  def restart_remote_endpoint
    load_impl
    self.send(__method__)
  end

  def stop_remote_endpoint
    load_impl
    self.send(__method__)
  end

  def destroy_remote_endpoint
    load_impl
    self.send(__method__)
  end

  def get_remote_deployment_status
    load_impl
    self.send(__method__)
  end

  def get_remote_execution_status
    load_impl
    self.send(__method__)
  end

  def get_remote_instance_status
    load_impl
    self.send(__method__)
  end

  def get_remote_configuration
    load_impl
    self.send(__method__)
  end

  def load_impl
    case self.endpoint.deployment_type
      when /Heroku/
        self.singleton_class.send(:include, DeployHerokuEndpointJobImpl)
      when /Unix/
        self.singleton_class.send(:include, DeployUnixEndpointJobImpl)
    end
  end

  def self.get_job(endpoint, action)
    job = self.where(:endpoint_id => endpoint.id).first
    if job.nil?
      case endpoint.at_type
        when "ServerEndpoint"
          job = DeployServerEndpointJob.new(:endpoint => endpoint)
          job_spec = DeployServerEndpointJobspec.new(job.id, action, endpoint.name)
        when "WorkerEndpoint"
          job = DeployWorkerEndpointJob.new(:endpoint => endpoint)
          job_spec = DeployWorkerEndpointJobspec.new(job.id, action, endpoint.name)
      end
      job.save
    end
    jobspec
  end

end