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

  key :start_command, :default => "script/start_backend.sh"
  key :stop_command, :default => "script/stop_backend.sh"
  key :restart_command, :default => "script/restart_backend.sh"
  key :configure_command, :default => "script/configure_backend.sh"

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

  def ssh_proxy_address
    server_proxies.select {|x| x.proxy_type == "SSH"}.first.local_proxy_address
  end

  def ssh_proxy_address=(addr)
    server_proxies.select {|x| x.proxy_type == "SSH"}.first.local_proxy_address = addr
  end

  def swift_proxy_address
    server_proxies.select {|x| x.proxy_type == "Swift"}.first.local_proxy_address
  end

  def swift_proxy_address=(addr)
    server_proxies.select {|x| x.proxy_type == "Swift"}.first.local_proxy_address = addr
  end

  def swift_backend_address
    server_proxies.select {|x| x.proxy_type == "Swift"}.first.local_backend_address
  end

  def swift_backend_address=(addr)
    server_proxies.select {|x| x.proxy_type == "Swift"}.first.local_backend_address = addr
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

  validates_presence_of :frontend
  validates_presence_of :installation
  before_validation :assign_upwards

  validate :validate_type

  def port_of(addr)
    match = /((.*):)?(.*)/ =~ addr
    match[3].to_i
  end

  def validate_type
    ports = frontend.backends.reduce([]) do |result, backend|
      if backend != self
        result + backend.local_proxy_ports + backend.local_backend_ports
      else
        result
      end
    end

    if ports.include?(port_of(ssh_proxy_address))
      self.errors.add(:ssh_proxy_address, "port taken in frontend")
    end
    if ports.include?(port_of(swift_proxy_address))
      self.errors.add(:ssh_proxy_address, "port taken in frontend")
    end
    if ports.include?(port_of(swift_backend_address))
      self.errors.add(:ssh_proxy_address, "port taken in frontend")
    end
  end

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
    installation_config ||= {}
    installation_config.merge JSON.parse(remote_configuration_literal)
  end

  def remote_configuration=(hash)
    n_json = hash.to_json
    self.remote_configuration_literal = n_json
  end

  key :endpoint_configuration_literal

  def endpoint_configuration
    begin
      installation_config = installation.remote_configuration
    rescue

    end
    installation_config ||= {}
    installation_config.merge JSON.parse(endpoint_configuration_literal)
  end

  def endpoint_configuration=(hash)
    n_json = hash.to_json
    self.endpoint_configuration_literal = n_json
  end

  def at_type
    return self._type
  end
end