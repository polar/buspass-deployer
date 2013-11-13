class DeployEndpointState < DeployState

  key :remote_status
  key :instance_status

  belongs_to :endpoint
end