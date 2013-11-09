class Endpoint
  include MongoMapper::Document

  key :name

  # The endpoint type, Heroku, Unix, etc.
  key :deployment_type

  # JSON String representing the variable configuration of the endpoint on the remote side.
  # TODO: Should be encrypted.
  key :remote_configuration_literal

  # Heroku Attributes
  key :heroku_app_name_store

  def heroku_app_name
    heroku_app_name_store || name
  end

  # Unix Attributes
  key :remote_user, :default => "busme"
  key :admin_user, :default => "uadmin"

  key :start_command, :default => "script/start_endpoint.sh"
  key :stop_command, :default => "script/stop_endpoint.sh"
  key :restart_command, :default => "script/restart_endpoint.sh"
  key :configure_command, :default => "script/configure_endpoint.sh"

  # Endpoints belong to Backends.
  belongs_to :backend

  # These are for queries they get assigned before saving should always be from the backend.
  belongs_to :frontend
  belongs_to :installation

  validates_uniqueness_of :name

  validates_presence_of :backend
  validates_presence_of :frontend
  validates_presence_of :installation

  before_validation :assign_upwards

  def assign_upwards
    self.frontend = backend.frontend
    self.installation = backend.installation
  end

  # This will be encrypted at some point.
  def remote_configuration
    JSON.parse(remote_configuration_literal)
  end

  def remote_configuration=(json)
    self.remote_configuration_literal = json.to_json
  end

  def at_type
    return self._type
  end

  def git_repository
  end

  def git_name
  end

  def git_refspec
  end

end