class Frontend
  include MongoMapper::Document

  key :host
  key :hostip
  key :host_type, :default => "ec2"
  key :configured, Boolean, :default => false
  key :log_level, Integer, :default => Logger::INFO

  key :git_commit
  key :listen_status, Array
  key :connection_status, Array

  key :endpoint_git_repository, :default => "git://github.com/polar/buspass-web.git"
  key :endpoint_git_refspec, :default => "HEAD"
  key :endpoint_git_name, :default => "buspass-web"

  belongs_to :deploy_frontend_job, :dependent => :destroy
  one :frontend_log

  one :frontend_key

  key :name

  many :backends, :dependent => :destroy

  before_validation :ensure_host, :ensure_name

  def ensure_host
    self.host = "#{hostip}" if host.nil?
  end

  def ensure_name
    self.name = "#{host}" if name.nil?
  end

  validates_uniqueness_of :host, :allow_nil => false
  validates_uniqueness_of :hostip, :allow_nil => false

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
    if self.frontend_log.nil?
      self.create_frontend_log
    end
    @my_logger           = MyLogger.new(self.frontend_log)
    @my_logger.level     = self.log_level
    @my_logger.formatter = Logger::Formatter.new
    @my_logger.datetime_format = "%Y-%m-%dT%H:%M:%S."
    return @my_logger
  end

  def log(s)
    logger.info s
  end

  def key_exists?
    frontend_key && frontend_key.exists?
  end
end