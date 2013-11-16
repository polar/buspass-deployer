class DeployEndpointState < DeployState

  key :remote_status
  key :listen_status
  key :connection_status
  key :instance_status

  belongs_to :endpoint
end