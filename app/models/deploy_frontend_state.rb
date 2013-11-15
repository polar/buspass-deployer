class DeployFrontendState < DeployState

  key :remote_status
  key :listen_status
  key :connection_status

  belongs_to :frontend, :autosave => false
  attr_accessible :frontend, :frontend_id
end