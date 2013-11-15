class Frontend
  include MongoMapper::Document

  key :name
  key :deployment_type  # "ha-proxy", "apache", "nginx", etc.

  #
  # ec2, unix, linode, etc.
  #
  key :provider_type

  # Unix Attributes
  key :remote_user, :default => "busme"
  key :admin_user, :default => "uadmin"

  key :start_command, :default => "scripts/start_frontend.sh"
  key :stop_command, :default => "scripts/stop_frontend.sh"
  key :restart_command, :default => "scripts/restart_frontend.sh"
  key :configure_command, :default => "scripts/configure_frontend.sh"

  key :git_commit, Array

  #
  # ssh stuff
  #
  # This user can create new users on the remote_host.
  key :remote_host

  # Assigned by configuration.
  key :external_ip

  # JSON String representing the variable configuration of the endpoint on the remote side.
  # TODO: Should be encrypted.
  key :remote_configuration_literal, :default => "{}"

  belongs_to :installation

  many :backends, :dependent => :destroy, :autosave => false
  many :endpoints, :autosave => false
  many :server_endpoints, :autosave => false
  many :worker_endpoints, :autosave => false


  before_validation :assign_upwards

  def assign_upwards
    self.name = self.name.gsub(/\s/, "_")
  end

  validates_uniqueness_of :name
  validate :must_be_json_hash

  def must_be_json_hash
    conf = remote_configuration
    errors.add(:remote_configuration_literal, "Must be a hash") unless conf.is_a? Hash
  rescue
    errors.add(:remote_configuration_literal, "Must be valid JSON")
  end

  validates_presence_of :installation

  attr_accessible :installation, :installation_id, :name, :remote_host, :remote_user, :admin_user, :deployment_type

  def allocated_backend_ports
    backends.reduce([]) do |result, backend|
      result + backend.local_backend_ports
    end
  end

  def allocated_proxy_ports
    backends.reduce([]) do |result, backend|
      result + backend.local_proxy_ports
    end
  end

  def git_repository
    installation.frontend_git_repository
  end

  def git_refspec
    installation.frontend_git_refspec
  end

  def git_name
    installation.frontend_git_name
  end

  # This will be encrypted at some point.
  def remote_configuration
    begin
      installation_config = installation.remote_configuration
    rescue

    end
    result = installation_config ||= {}
    result = result.merge JSON.parse(remote_configuration_literal) if remote_configuration_literal && !remote_configuration_literal.blank?
    result =  result.merge({
                              "INSTALLATION" => installation.name,
                              "FRONTEND" => name,
                          })
    result
  end

  def remote_configuration=(json)
    self.remote_configuration_literal = json.to_json
  end

  def at_type
    return self.respond_to?("_type") ? self._type : "Frontend"
  end
end