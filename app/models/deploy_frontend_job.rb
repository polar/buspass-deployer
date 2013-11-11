class DeployFrontendJob
  include MongoMapper::Document

  one :frontend, :autosave => false
  key :status_content
  key :state_destroy, :default => false

  def installation
    frontend.installation
  end

  def state
    return @state if @state
    @state = DeployFrontendState.where(:frontend_id => frontend.id).first
    if @state.nil?
      @state = DeployFrontendState.new(:frontend_id => frontend.id)
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
      when "ec2"
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