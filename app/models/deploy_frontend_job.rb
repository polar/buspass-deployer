class DeployFrontendJob < DeployJob

  def installation
    frontend.installation
  end

  def git_commit
    state.git_commit
  end

  def listen_status
    state.listen_status
  end

  def connection_status
    state.connection_status
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
    case self.frontend.deployment_type
      when "nginx"
        self.singleton_class.send(:include, DeployUnixFrontendJobImpl)
      when "unix"
        self.singleton_class.send(:include, DeployUnixFrontendJobImpl)
    end
  end

  def self.get_job(frontend, action)
    job = self.where(:frontend_id => frontend.id).first
    if job.nil?
      job = DeployFrontendJob.new(:frontend => frontend)
      job.save
    end
    DeployFrontendJobspec.new(job.id, action)
  end

end