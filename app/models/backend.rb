#
# Backends receive connections from the Frontend for specific host names
# and locations. Backends are configured on the Frontend's Machine
# A Swift Backend runs a proxy on the Frontend Machine accepting local
# connections from the Frontend and accepting Swift enabled Endpoint connections
# on the local_proxy_addresses
#
# A ssh Backend allows a SSH tunnel to be set up on its proxy_addresses which
# forwards to ServerEndpoints though that tunnel.
#
# An ha-proxy runs on the Frontend Machine to a unspecified configuration of
# endpoints.
#
class Backend
  include MongoMapper::Document

  key :name

  # Unix Attributes
  key :remote_user, :default => "busme"
  key :admin_user, :default => "uadmin"

  key :start_command, :default => "scripts/start_backend.sh"
  key :stop_command, :default => "scripts/stop_backend.sh"
  key :restart_command, :default => "scripts/restart_backend.sh"
  key :configure_command, :default => "scripts/configure_backend.sh"

  # array of host names or host name matches
  # ["syracuse-ny.busme.us", "*.syracuse-ny.busme.us"]
  key :hostnames, Array

  # ["/syracuse-ny", "/jackson-wy"]
  key :locations, Array

  # Embedded
  many :server_proxies, :dependent => :destroy

  def local_proxy_ports
    server_proxies.reduce([]) do |result, proxy|
      if ["Swift", "SSH"].include? proxy.proxy_type
        match = /((.*):)(.*)/.match proxy.proxy_address
        result + (match ? [match[3].to_i] : [])
      else
        result
      end
    end
  end

  def local_backend_ports
    server_proxies.reduce([]) do |result, proxy|
      if ["Swift"].include? proxy.proxy_type
        match = /((.*):)(.*)/.match proxy.backend_address
        result + (match ? [match[3].to_i] :[])
      else
        result
      end
    end
  end

  def proxy_addresses
    server_proxies.reduce([]) do |result, proxy|
        result + [proxy.proxy_address]
    end
  end

  # JSON String representing the variable configuration of the endpoint on the remote side.
  # TODO: Should be encrypted.
  key :remote_configuration_literal


  belongs_to :frontend
  belongs_to :installation

  many :endpoints, :dependent => :destroy, :autosave => false

  many :worker_endpoints, :dependent => :destroy, :autosave => false
  many :server_endpoints, :dependent => :destroy, :autosave => false

  validates_uniqueness_of :name

  validates_presence_of :name
  validates_presence_of :frontend
  validates_presence_of :installation
  before_validation :assign_upwards

  def assign_upwards
    self.name = self.name.gsub(/\s/, "_")
    self.installation = frontend.installation
  end

  # This will be encrypted at some point.
  def remote_configuration
    begin
      installation_config = installation.remote_configuration
    rescue

    end
    result = installation_config ||= {}
    result = result.merge JSON.parse(remote_configuration_literal) if remote_configuration_literal && ! remote_configuration_literal.blank?

    result = result.merge({
                              "INSTALLATION" => installation.name,
                              "FRONTEND" => frontend.name,
                              "BACKEND" => name,
                          })
    result
  end

  def remote_configuration=(hash)
    n_json = hash.to_json
    self.remote_configuration_literal = n_json
  end

  key :endpoint_configuration_literal

  def endpoint_configuration
    result = {}
    result = result.merge JSON.parse(endpoint_configuration_literal) if endpoint_configuration_literal  && ! endpoint_configuration_literal.blank?
    result
  end

  def endpoint_configuration=(hash)
    n_json = hash.to_json
    self.endpoint_configuration_literal = n_json
  end

  def at_type
    return self._type
  end
end