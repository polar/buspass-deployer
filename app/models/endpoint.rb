class Endpoint
  include MongoMapper::Document

  key :name

  # The endpoint type, Heroku, Heroku-Swift, Unix, Unix-Swift, etc.
  key :deployment_type

  # JSON String representing the variable configuration of the endpoint on the remote side.
  # TODO: Should be encrypted.
  key :remote_configuration_literal

  # Heroku Attributes
  key :heroku_app_name_store

  def heroku_app_name
    heroku_app_name_store || name.downcase.gsub(/_+/, "-")
  end

  def heroku_app_name=(name)
    n_name = name.downcase.gsub(/\s+/,"-")
    self.heroku_app_name_store = n_name  if heroku_app_name != n_name
  end

  def deploy_heroku_api_key
    installation.deploy_heroku_api_key
  end

  # Unix Attributes
  key :remote_user, :default => "busme"
  key :admin_user, :default => "uadmin"

  key :remote_host

  key :n_servers, Integer, :default => 1

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

  def remote_name
    case deployment_type
      when /Heroku/
        heroku_app_name
      else
        remote_host
    end
  end

  def assign_upwards
    self.name = self.name.gsub(/\s/, "_")
    self.frontend = backend.frontend
    self.installation = backend.installation
  end

  # This will be encrypted at some point.
  def remote_configuration
    begin
      installation_config = installation.remote_configuration
    rescue

    end
    endpoint_config = case at_type
                        when "ServerEndpoint"
                          "SERVER_ENDPOINT"
                        when "WorkerEndpoint"
                          "WORKER_ENDPOINT"
                      end
    result = installation_config ||= {}
    result = result.merge backend.endpoint_configuration
    result = result.merge JSON.parse(remote_configuration_literal) if remote_configuration_literal
    result = result.merge({
                "INSTALLATION" => installation.name,
                "FRONTEND" => frontend.name,
                "BACKEND" => backend.name,
                "ENDPOINT" => name,
                endpoint_config => name,
              })
    result
  end

  def remote_configuration=(json)
    self.remote_configuration_literal = json.to_json
  end

  def at_type
    return self._type
  end

  def git_repository
    raise "Unimplemented"
  end

  def git_name
    raise "Unimplemented"
  end

  def git_refspec
    raise "Unimplemented"
  end

end