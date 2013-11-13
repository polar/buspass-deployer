class DeployJob
  include MongoMapper::Document

  key :status_content

  belongs_to :installation
  belongs_to :frontend
  belongs_to :backend
  belongs_to :endpoint

  belongs_to :deploy_state, :autosave => false

  def state
    return @state if @state
    if endpoint
      @state = DeployEndpointState.where(:endpoint_id => endpoint.id).first
    elsif backend
      @state = DeployBackendState.where(:backend_id => backend.id).first
    elsif frontend
      @state = DeployFrontendState.where(:frontend_id => frontend.id).first
    elsif installation
      @state = DeployInstalltionState.where(:installation_id => installation.id).first
    end

    if @state.nil?
      if endpoint
        @state = DeployEndpointState.new(:endpoint => endpoint)
      elsif backend
        @state = DeployBackendState.new(:backend => backend)
      elsif frontend
        @state = DeployFrontendState.new(:frontend => frontend)
      elsif installation
        @state = DeployInstalltionState.new(:installation => installation)
      end
      @state.save
    end
    @state
  end

  def set_status(s)
    self.status_content = s
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

  def log(s)
    state.logger.log(state.log_level, s)
  end

  def to_a()
    state.logger.to_a
  end

  def segment(i, n)
    state.logger.segment(i, n)
  end

end