class DeployBackendState
  include MongoMapper::Document

  key :status
  key :log_level, Integer, :default => Logger::INFO
  timestamps!

  key :listen_status
  key :connection_status

  belongs_to :backend
  belongs_to :deploy_backend_log

  attr_accessible :backend, :backend_id
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
    if self.deploy_backend_log.nil?
      self.create_deploy_backend_log
    end
    @my_logger           = MyLogger.new(self.deploy_backend_log)
    @my_logger.level     = self.log_level
    @my_logger.formatter = Logger::Formatter.new
    @my_logger.datetime_format = "%Y-%m-%dT%H:%M:%S."
    return @my_logger
  end

  def log(s)
    logger.info s
  end
end