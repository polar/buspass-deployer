class DeployFrontendJob
  include MongoMapper::Document
  include DeployUnixOperations

  one :frontend, :autosave => false

  key :status_content

  def ssh_cert
    if frontend.remote_key
      if ! File.exists?(frontend.remote_key.ssh_key.file.path) && frontend.remote_key.key_encrypted_content
         frontend.remote_key.decrypt_key_content_to_file
      end
      return frontend.remote_key.ssh_key.file.path
    end
  end

  def state
    return @state if @state
    @state = DeployBackendState.where(:backend_id => backend.id).first
    if @state.nil?
      @state = DeployBackendState.new(:backend_id => backend.id)
      @state.save
    end
    @state
  end

  def log(s)
    state.logger.log(@state.log_level, s)
  end

  def set_status(s, rs = nil)
    self.status_content = s
    save
    state.status = s
    state.remote_status = rs if rs
    state.save
    log("status: #{s}")
    log("remote status: #{rs.inspect}") if rs
  end

  def delayed_jobs
    Delayed::Job.where(:queue => "deploy-web", :failed_at => nil).select do |job|
      job.payload_object.is_a?(DeployFrontendJobspec) && job.payload_object.deploy_frontend_job_id == self.id
    end
  end

  def ssh_cmd(cmd)
    unix_ssh_cmd(frontend.remote_host, frontend.remote_key, frontend.remote_user, cmd)
  end

  def scp_cmd(path, remote_path)
    unix_scp_cmd(frontend.remote_host, frontend.remote_key, frontend.remote_user, path, remote_path)
  end

  def create_remote_frontend
    load_impl
    self.send(__method__)
  end

  def configure_remote_frontend
    load_impl
    self.send(__method__)
  end

  def deconfigure_remote_frontend
    load_impl
    self.send(__method__)
  end

  def deploy_remote_frontend
    load_impl
    self.send(__method__)
  end

  def status_remote_frontend
    load_impl
    self.send(__method__)
  end

  def start_remote_frontend
    load_impl
    self.send(__method__)
  end

  def stop_remote_frontend
    load_impl
    self.send(__method__)
  end

  def restart_remote_frontend
    load_impl
    self.send(__method__)
  end

  def destroy_frontend
    load_impl
    self.send(__method__)
  end

  def load_impl
    case self.endpoint.deployment_type
      when "Heroku"
        self.singleton_class.send(:include, DeployHerokuEndpointJobImpl)
      when "Unix"
        self.singleton_class.send(:include, DeployUnixEndpointJobImpl)
    end
  end


end