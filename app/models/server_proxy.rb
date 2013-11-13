class ServerProxy
  include MongoMapper::Document

  key :proxy_type
  key :local_proxy_address
  key :local_backend_address

  belongs_to :backend

  belongs_to :server_endpoint

  validates_presence_of :local_proxy_address, :if => lambda { ["Swift", "SSH"].include? proxy_type }
  validates_presence_of :local_backend_address, :if => lambda { proxy_type == "Swift" }

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
    local_backend_address
  end

end