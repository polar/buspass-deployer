class DeployJob
  include MongoMapper::Document

  key :status_content

  belongs_to :installation
  belongs_to :frontend
  belongs_to :backend
  belongs_to :endpoint

  belongs_to :deploy_state, :autosave => false, :dependent => :destroy
  before_validation :assign_upwards

  def assign_upwards
    if endpoint
      self.backend = endpoint.backend
    end
    if backend
      self.frontend = backend.frontend
    end
    if frontend
      self.installation = frontend.installation
    end
  end

  def state
    return @state if @state
    if endpoint
      @state = DeployEndpointState.where(:endpoint_id => endpoint.id).first
    elsif backend
      @state = DeployBackendState.where(:backend_id => backend.id).first
    elsif frontend
      @state = DeployFrontendState.where(:frontend_id => frontend.id).first
    elsif installation
      @state = DeployInstallationState.where(:installation_id => installation.id).first
    end

    if @state.nil?
      if endpoint
        @state = DeployEndpointState.new(:endpoint => endpoint)
      elsif backend
        @state = DeployBackendState.new(:backend => backend)
      elsif frontend
        @state = DeployFrontendState.new(:frontend => frontend)
      elsif installation
        @state = DeployInstallationState.new(:installation => installation)
      end
      @state.save
    end
    @state
  end

  def delayed_jobs
    Delayed::Job.where(:queue => "deploy-web").reduce([]) do |result, x|
      if x.payload_object.is_a?(DeployJobspec) && x.payload_object.job_id == self.id
        result + [x]
      else
        result
      end
    end
  end

  def set_status(s, rs = nil)
    self.status_content = s
    if rs
      state.remote_status = rs
      log("remote_status #{rs}")
      state.save
    end
    save
    log("status: #{s}")
  end

  def get_status
    status_content
  end

  def logger
    state.logger
  end

  def status
    status_content
  end

  def updated_at
    state.updated_at
  end

  def remote_status
    state.remote_status
  end

  def ssh_cert
    if @ssh_cert
      return @ssh_cert
    end
    remote_key = RemoteKey.find_by_name(frontend.installation.ssh_key_name)
    if ! File.exists?(remote_key.ssh_key.file.path) && remote_key.key_encrypted_content
      remote_key.decrypt_key_content_to_file(:key => ENV["AWS_SECRET_ACCESS_KEY"])
    end
    @ssh_cert = remote_key.ssh_key.file.path
  end

  # For now, its the same as the ssh_cert, which is used for *everything*.
  def deploy_cert
    if @deploy_cert
      return @deploy_cert
    end
    remote_key = RemoteKey.find_by_name(frontend.installation.ssh_key_name)
    if ! File.exists?(remote_key.ssh_key.file.path) && remote_key.key_encrypted_content
      remote_key.decrypt_key_content_to_file(:key => ENV["AWS_SECRET_ACCESS_KEY"])
    end
    @deploy_cert = remote_key.ssh_key.file.path
  end

  def pub_cert(cert_path)
    file = Tempfile.new("cert.pub")
    Rush.bash("ssh-keygen -y -f #{cert_path} > #{file.path}")
    return file
  end

  def log(s)
    state.logger.log(state.log_level, s)
  end

  def to_a()
    state.logger.to_a
  end

  def segment(i, n)
    state.logger.segment(i, n)
  end

  def destroy
    deploy_state.destroy if deploy_state
    super
  end
end