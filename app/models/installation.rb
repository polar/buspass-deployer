class Installation
  include MongoMapper::Document

  key :name
  key :log_level, Integer, :default => Logger::INFO

  key :swift_endpoint_git_repository, :default => "git://github.com/polar/buspass-web.git"
  key :swift_endpoint_git_refspec, :default => "HEAD"
  key :swift_endpoint_git_name, :default => "buspass-web"

  key :worker_endpoint_git_repository, :default => "git://github.com/polar/buspass-workers.git"
  key :worker_endpoint_git_refspec, :default => "HEAD"
  key :worker_endpoint_git_name, :default => "buspass-workers"

  key :frontend_git_repository, :default => "git://github.com/polar/busme-swifty.git"
  key :frontend_git_refspec, :default => "HEAD"
  key :frontend_git_name, :default => "busme-swifty"

  belongs_to :deploy_installation_job, :dependent => :destroy
  one :installation_log
  timestamps!


  many :frontends

  validates_presence_of :name
  validates_uniqueness_of :name

  def job_status
    deploy_installation_job.get_status if deploy_installation_job
  end

  def backends
    frontends.all.reduce( [] ){ |t,fe| t + fe.backends}
  end

  def swift_endpoints
    frontends.all.reduce( [] ){ |t,fe| t + fe.swift_endpoints}
  end

  def worker_endpoints
    frontends.all.reduce( [] ){ |t,fe| t + fe.worker_endpoints}
  end

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
    if self.installation_log.nil?
      self.create_installation_log
    end
    @my_logger           = MyLogger.new(self.installation_log)
    @my_logger.level     = self.log_level
    @my_logger.formatter = Logger::Formatter.new
    @my_logger.datetime_format = "%Y-%m-%dT%H:%M:%S."
    return @my_logger
  end

  def log(s)
    logger.info s
  end


end