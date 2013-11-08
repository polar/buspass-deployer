class Endpoint
  include MongoMapper::Document

  # The endpoint type, Heroku, Unix, etc.
  key :deployment_type

  key :name

  # JSON String representing the variable configuration of the endpoint on the remote side.
  # TODO: Should be encrypted.
  key :remote_configuration_literal

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