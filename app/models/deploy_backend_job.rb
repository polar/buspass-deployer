class DeployBackendJob < DeployJob

  key :listen_status, Array

  def ssh_cert
    if @ssh_cert
      return @ssh_cert
    end
    remote_key = RemoteKey.find_by_name(frontend.installation.ssh_key_name)
    if ! File.exists?(remote_key.ssh_key.file.path) && remote_key.key_encrypted_content
      remote_key.decrypt_key_content_to_file
    end
    @ssh_cert = remote_key.ssh_key.file.path
  end

  def delayed_jobs
    Delayed::Job.where(:queue => "deploy-web").reduce([]) do |result, x|
      if x.payload_object.is_a?(DeployBackendJobspec) && x.payload_object.backend_job_id == self.id
        result + [x]
      else
        result
      end
    end
  end

  def frontend
    backend.frontend
  end

  # We are assuming
  def create_remote_backend
    load_impl
    self.send(__method__)
  end

  def configure_remote_backend
    load_impl
    self.send(__method__)
  end

  def deconfigure_remote_backend
    load_impl
    self.send(__method__)
  end

  def deploy_to_remote_backend
    load_impl
    self.send(__method__)
  end

  def start_remote_backend
    load_impl
    self.send(__method__)
  end

  def stop_remote_backend
    load_impl
    self.send(__method__)
  end

  def restart_remote_backend
    load_impl
    self.send(__method__)
  end

  def status_remote_backend
    load_impl
    self.send(__method__)
  end

  def destroy_remote_backend
    load_impl
    self.send(__method__)
  end

  def apply_to_endpoint(method, endpoint)
    if endpoint && endpoint.backend == self.backend
      job = DeployEndpointJob.get_job(endpoint)
      djob = job.jobspec(endpoint.name, method)
      Delayed::Job.enqueue(djob, :queue => "deploy-web")
    end
  end

  def start_all_endpoints
    backend.endpoints.each do |endpoint|
      apply_to_endpoint("start_remote_endpoint", endpoint)
    end
  end

  def restart_all_endpoints
    backend.endpoints.each do |endpoint|
      apply_to_endpoint("restart_remote_endpoint", endpoint)
    end
  end

  def stop_all_endpoints
    backend.endpoints.each do |endpoint|
      apply_to_endpoint("stop_remote_endpoint", endpoint)
    end
  end

  def deploy_to_all_endpoints
    backend.endpoints.each do |endpoint|
      apply_to_endpoint("deploy_to_remote_endpoint", endpoint)
    end
  end

  def destroy_all_endpoints
    backend.endpoints.each do |endpoint|
      apply_to_endpoint("destroy_remote_endpoint", endpoint)
    end
  end

  def load_impl
    case backend.deployment_type
      when "swift"
        self.singleton_class.send(:include, DeploySwiftBackendJobImpl)
      when "ssh"
        self.singleton_class.send(:include, DeploySshBackendJobImpl)
    end
  end

  def self.get_job(backend, action)
    job = DeployBackendJob.where(:backend_id => backend.id).first
    if job.nil?
      job = DeployBackendJob.new(:backend => backend)
      job.save
    end
    DeployBackendJobspec.new(job.id, action)
  end

end