class Backend
  include MongoMapper::Document

  key :frontend_address, String, :default => "0.0.0.0"
  key :master_slug
  key :frontend_local, Boolean, :default => true
  key :hostname
  key :server_name
  key :cluster_address, String, :default => "127.0.0.1"
  key :cluster_port
  key :address, String, :default => "0.0.0.0"
  key :port
  key :timeout
  key :log_level, Integer, :default => Logger::INFO

  key :listen_status
  key :connection_status

  key :configured, Boolean, :default => false

  key :name
  timestamps!

  belongs_to :frontend
  one :backend_log, :dependent => :destroy
  one :deploy_backend_job, :dependent => :destroy
  many :swift_endpoints
  many :worker_endpoints

  before_validation :ensure_hostname, :ensure_name

  attr_accessible :frontend, :frontend_id
  attr_accessible :frontend_address, :master_slug, :hostname
  attr_accessible :server_name, :cluster_address, :cluster_port, :address, :port

  def job_status
    deploy_backend_job.get_status if deploy_backend_job
  end

  def installation
    frontend.installation
  end

  def frontend_name
    frontend.name
  end

  def ensure_hostname
    if ! master_slug.blank?
      self.hostname = "#{master_slug}.#{frontend.host}"
    end

    if hostname.blank?
      self.hostname    = "#{frontend.host}"
      self.server_name = "*.#{frontend.host}" if server_name.blank?
    end
  end

  def host
    if frontend_local && address == "0.0.0.0"
      frontend.host
    else
      address
    end
  end

  def ensure_name
    if name.nil?
      if master_slug.blank?
        self.name = "Z-#{frontend.name}-#{hostname}-#{frontend_address}-#{cluster_address}-#{cluster_port}-#{address}-#{port}"
      else
        self.name = "A-#{frontend.name}-#{hostname}-#{frontend_address}-#{cluster_address}-#{cluster_port}-#{address}-#{port}"
      end
    end
    return name
  end

  def spec
    "#{name}"
  end

  validates_uniqueness_of :name
  validates_presence_of :frontend_address
  validates_presence_of :cluster_address
  validates_numericality_of :cluster_port
  validates_uniqueness_of :cluster_port, :scope => [:cluster_address, :frontend_id]
  validates_presence_of :address
  validates_numericality_of :port
  validates_uniqueness_of :port, :scope => [:cluster_address, :frontend_id]



  class MyLogger < Logger
    def initialize(log, opts = { })
      super
      @joblog = log
    end

    def to_a
      @joblog.to_a
    end

    def segment(x, y)
      @joblog.segment(x, y)
    end
  end

  def logger
    if @my_logger
      @my_logger.level = self.log_level
      return @my_logger
    end
    if self.backend_log.nil?
      self.create_backend_log
    end
    @my_logger           = MyLogger.new(self.backend_log)
    @my_logger.level     = self.log_level
    @my_logger.formatter = Logger::Formatter.new
    @my_logger.datetime_format = "%Y-%m-%dT%H:%M:%S."
    return @my_logger
  end

  def log(s)
    logger.info s
  end
end
