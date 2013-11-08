class DeployBackend1Job
  include MongoMapper::Document

  key :status_content

  belongs_to :backend, :class_name => "Backend1"

  attr_accessible :backend, :backend_id

  def state
    return @state if @state
    @state = DeployBackendState.where(:backend_id => backend.id).first
  end

  def log(s)
    state.logger.log(s)
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

  # We are assuming
  def create_remote_backend
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

end