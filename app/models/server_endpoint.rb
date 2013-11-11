class ServerEndpoint < Endpoint

  validates_presence_of :remote_user, :if => lambda { ["Unix", "Unix-SSH"].include? deployment_type }
  validates_presence_of :remote_host, :if => lambda { ["Unix", "Unix-SSH"].include? deployment_type }

  after_save :ensure_backend_server_proxy

  def ensure_backend_server_proxy
    if ["Unix", "Heroku"].include? deployment_type
      if backend.server_proxies.select {|x| x.proxy_type == "Server" && x.server_endpoint == self}.empty?
        backend.server_proxies.build(
            :proxy_type => "Server",
            :server_endpoint => self
        )
        backend.save
      end
    end
  end

  def git_repository
    installation.server_endpoint_git_repository
  end

  def git_name
    installation.server_endpoint_git_name
  end

  def git_refspec
    installation.server_endpoint_git_refspec
  end
end