class DeployBackendState < DeployState

  key :listen_status
  key :connection_status

  belongs_to :backend

  attr_accessible :backend, :backend_id
end