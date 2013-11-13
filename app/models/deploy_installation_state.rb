class DeployInstallationState < DeployState

  belongs_to :installation, :autosave => false
  attr_accessible :installation, :installation_id

end