class ServerEndpoint < Endpoint

  validates_presence_of :remote_user, :if => lambda { ["Unix", "Unix-SSH"].include? deployment_type }
  validates_presence_of :remote_host, :if => lambda { ["Unix", "Unix-SSH"].include? deployment_type }

  one :server_proxy, :dependent => :destroy

  after_save :ensure_backend_server_proxy

  # For ServerEndpoint only.

  def backend_address
    @backend_address || (server_proxy.backend_address if server_proxy)
  end

  def backend_address=(addr)
    @backend_address = addr
    server_proxy.external_backend_address = addr if server_proxy
  end

  key :proxy_address_store, :default => nil

  def proxy_address
    proxy_address_store ||
        case deployment_type
          when "Heroku"
            "https://#{heroku_app_name}.herokuapp.com"
          when "Unix"
            "http://#{remote_host}"
          else
            server_proxy.local_proxy_address if server_proxy
        end
  end

  validates_presence_of :proxy_address, :if => lambda { at_type == "ServerEndpoint" && ["Heroku", "Unix"].include?(deployment_type)}

  def proxy_address=(addr)
    if addr.blank?
      self.proxy_address_store = nil
    else
      self.proxy_address_store = addr  if self.proxy_address != addr
    end
  end

  def ensure_backend_server_proxy
    my_proxy = backend.server_proxies.where(:server_endpoint_id => self.id).first
    if my_proxy
      if ["Unix-Swift", "Heroku-Swift"].include?(deployment_type) && "Swift" != my_proxy.proxy_type
        my_proxy.destroy
      elsif ["Unix-SSH"].include?(deployment_type) && "SSH" != my_proxy.proxy_type
        my_proxy.destroy
      elsif ["Unix","Heroku"].include?(deployment_type) && "Server" != my_proxy.proxy_type
        my_proxy.destroy
      else
        return
      end
    end
    if ["Unix", "Heroku"].include? deployment_type
      if backend.server_proxies.select {|x| x.proxy_type == "Server" && x.server_endpoint == self}.empty?
        backend.server_proxies.create(
            :proxy_type => "Server",
            :server_endpoint => self
        )
      end
    elsif ["Unix-SSH", "Unix-Swift", "Heroku-Swift"].include? deployment_type
      proxy_ports   = frontend.allocated_proxy_ports
      backend_ports = frontend.allocated_backend_ports
      if ["Unix-SSH"].include? deployment_type
        proxy = backend.server_proxies.select {|x| x.proxy_type == "SSH" && x.server_endpoint.nil? }.first
        if proxy
          proxy.server_endpoint = self
          proxy.save
        else
          ssh_proxy_port     = (proxy_ports.max || 2999) + 1
          proxy = backend.server_proxies.build(
              :proxy_type => "SSH",
              :server_endpoint => self,
              :local_proxy_address => "127.0.0.1:#{ssh_proxy_port}"
          )
          if @backend_address
            proxy.external_backend_address = @backend_address
          end
          proxy.save
          addr = proxy.local_proxy_address
        end
      else
        proxy = backend.server_proxies.select {|x| x.proxy_type == "Swift"}.first
        if proxy
          proxy = backend.server_proxies.build(
              :proxy_type => "Swift",
              :server_endpoint => self,
              :local_proxy_address => proxy.local_proxy_address,
              :local_backend_address => proxy.local_backend_address,
              :external_backend_address => proxy.external_backend_address
          )
          proxy.save
        else
          swift_proxy_port   = (proxy_ports.max || 2999) + 1
          swift_backend_port = (backend_ports.max || 3999) + 1
          proxy = backend.server_proxies.build(
              :proxy_type => "Swift",
              :server_endpoint => self,
              :local_proxy_address => "127.0.0.1:#{swift_proxy_port}",
              :local_backend_address => "0.0.0.0:#{swift_backend_port}"
          )
          if @backend_address
            proxy.external_backend_address = @backend_address
          end
          proxy.save
        end
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