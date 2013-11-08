class DeployEndpointJob
  include MongoMapper::Document

  key :status_content

  belongs_to :endpoint

  attr_accessible :endpoint, :endpoint_id

  def state
    return @state if @state
    @state = DeployEndpointState.where(:endpoint_id => endpoint.id).first
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

  #
  # Ugg is there a better way?
  # It seems that we only can tell if we haven't loaded the proper
  # implementation yet until we call it.
  def load_impl
    case self.endpoint.deployment_type
      when "Heroku"
        self.singleton_class.send(:include, DeployHerokuEndpointJobImpl)
      when "Unix"
        self.singleton_class.send(:include, DeployUnixEndpointJobImpl)
    end
  end

  def self.get_job(endpoint)
    job = self.where(:endpoint_id => endpoint.id).first
    if job.nil?
      case endpoint.at_type
        when "ServerEndpoint1"
          job = DeployServerEndpoint1Job.new(:endpoint => endpoint)
        when "SwiftEndpoint1"
          job = DeploySwiftEndpoint1Job.new(:endpoint => endpoint)
        when "WorkerEndpoint1"
          job = DeployWorkerEndpoint1Job.new(:endpoint => endpoint)
      end
      if job
        job.save
      end
    end
  end

end