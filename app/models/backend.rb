#
# Backends receive connections from the Frontend for specific host names
# and locations. Backends are configured on the Frontend's Machine
# A Swift Backend runs a proxy on the Frontend Machine accepting local
# connections from the Frontend and accepting SwiftEndpoint connections
# on the swift_addresses
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
  key :deployment_type  # "swift", "ssh", "ha-proxy"

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

  #
  # Addresses connections two which the Frontend forwards.
  #   ["127.0.0.1:4001", "unix:/tmp/named_socket"]
  #
  key :proxy_addresses, Array

  #
  # Addresses to which a Swiftiply client will connect a Swift Cluster Backend
  # or some other proxy software that handles establishment of endpoints via
  # these addresses as management. For instance a SwiftEndpoint connects to
  # one of these addresses (usually one) and sends a key, and that establishes
  # it as a viable server.
  # ["0.0.0.0:3001", "192.168.99.2:3002"]
  #
  key :backend_addresses, Array

  # JSON String representing the variable configuration of the endpoint on the remote side.
  # TODO: Should be encrypted.
  key :remote_configuration_literal


  belongs_to :frontend
  belongs_to :installation

  many :endpoints, :dependent => :destroy, :autosave => false

  many :swift_endpoints, :dependent => :destroy, :autosave => false
  many :worker_endpoints, :dependent => :destroy, :autosave => false
  many :server_endpoints, :dependent => :destroy, :autosave => false

  validates_uniqueness_of :name

  validates_presence_of :frontend
  validates_presence_of :installation
  before_validation :assign_upwards

  def assign_upwards
    self.installation = frontend.installation
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
end