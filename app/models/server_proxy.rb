class ServerProxy
  include MongoMapper::Document

  #
  #  Swift, SSH, Server
  #
  key :proxy_type

  #
  # Can be any valid URL to which the Nginx forwards.
  #
  #   127.0.0.0:3000
  #   http://servers.busme.com
  #   https://localip:3000
  #   unix:/tmp/socket-1
  #
  key :local_proxy_address

  #
  # Names the local interface and port on the frontend
  # to which the SWIFT endpoints connect
  #   0.0.0.0:4000      all interfaces
  #   192.9.9.2:400     A particular interface
  #
  key :local_backend_address

  # The SWIFT backend address that is not derivable from the local_backend_address
  # for reasons of firewalls, and other proxies. Must have a port number.
  #   portal.busme.com:4000
  #   128.23.22.33:4000
  #   e4:34:da:21:89:34:22:4000
  key :external_backend_address

  belongs_to :backend

  belongs_to :server_endpoint

  validates_presence_of :local_proxy_address, :if => lambda { ["Swift", "SSH"].include? proxy_type }
  validates_presence_of :local_backend_address, :if => lambda { proxy_type == "Swift" }
  validates_format_of :local_backend_address, :with => /(.*):([0-9]+)$/, :allow_blank => true, :allow_nil => true

  validate :everything_else

  def everything_else
    if proxy_type == "Server"
      if server_endpoint.nil?
        self.errors.add(:server_endpoint, "cannnot be empty")
      else
        if not ["Heroku", "Unix"].include? server_endpoint.deployment_type
          self.errors.add(:server_endpoint, "must be of the Heroku or Unix type")
        end
      end
    end
  end

  def proxy_address
    case proxy_type
      when "Server"
        server_endpoint.proxy_address
      else
        local_proxy_address
    end
  end

  def backend_address
    if external_backend_address && !external_backend_address.blank?
      return external_backend_address
    elsif local_backend_address && !local_backend_address.blank?
      match = /(.*):([0-9]+)/.match local_backend_address
      port = match[2]
      host = match[1]
      if host == "0.0.0.0"
        host = server_endpoint.frontend.external_ip
        if host.blank?
          host = server_endpoint.frontend.remote_host
        end
      end
      return "#{host}:#{port}"
    end
  end

end