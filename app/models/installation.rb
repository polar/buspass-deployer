class Installation
  include MongoMapper::Document

  key :name
  key :ssh_key_name

  key :server_endpoint_git_repository, :default => "git://github.com/polar/buspass-web.git"
  key :server_endpoint_git_refspec, :default => "master"
  key :server_endpoint_git_name, :default => "buspass-web"

  key :swift_endpoint_git_repository, :default => "git://github.com/polar/buspass-web.git"
  key :swift_endpoint_git_refspec, :default => "master"
  key :swift_endpoint_git_name, :default => "buspass-web"

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
  many :swift_endpoints, :autosave => false
  many :worker_endpoints, :autosave => false

  validates_presence_of :name
  validates_uniqueness_of :name

end