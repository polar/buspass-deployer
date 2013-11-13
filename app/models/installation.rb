class Installation
  include MongoMapper::Document

  key :name
  key :ssh_key_name
  key :deploy_heroku_api_key_name
  key :remote_configuration_literal

  key :server_endpoint_git_repository, :default => "git://github.com/polar/buspass-web.git"
  key :server_endpoint_git_refspec, :default => "master"
  key :server_endpoint_git_name, :default => "buspass-web"

  key :worker_endpoint_git_repository, :default => "git://github.com/polar/buspass-workers.git"
  key :worker_endpoint_git_refspec, :default => "master"
  key :worker_endpoint_git_name, :default => "buspass-workers"

  key :frontend_git_repository, :default => "git://github.com/polar/busme-swifty.git"
  key :frontend_git_refspec, :default => "master"
  key :frontend_git_name, :default => "busme-swifty"

  timestamps!

  many :frontends, :autosave => false, :dependent => :destroy
  many :backends, :autosave => false
  many :endpoints, :autosave => false
  many :server_endpoints, :autosave => false
  many :worker_endpoints, :autosave => false

  validates_presence_of :name
  validates_uniqueness_of :name
  validate :must_be_json_hash
  validate :existence_of_keys

  def existence_of_keys
    if !ssh_key_name.blank?
      if RemoteKey.find_by_name(ssh_key_name).nil?
        self.errors.add(:ssh_key_name, "does not exist")
      end
    end
    if !deploy_heroku_api_key_name.blank?
      if DeployHerokuApiKey.find_by_name(deploy_heroku_api_key_name).nil?
        self.errors.add(:deploy_heroku_api_key_name, "does not exist")
      end
    end
  end

  def must_be_json_hash
    conf = remote_configuration
    errors.add(:remote_configuration_literal, "Must be a hash") unless conf.is_a? Hash
  rescue
    errors.add(:remote_configuration_literal, "Must be valid JSON")
  end

  # This will be encrypted at some point.
  def remote_configuration
    JSON.parse(remote_configuration_literal) if remote_configuration_literal && ! remote_configuration_literal.blank?
  end

  def remote_configuration=(json)
    self.remote_configuration_literal = json.to_json
  end

end