class DeployInstallationState
  include MongoMapper::Document

  key :status
  key :log_level, Integer, :default => Logger::INFO
  timestamps!

  belongs_to :installation, :autosave => false
  belongs_to :deploy_installation_log

  attr_accessible :installation, :installation_id

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
    if self.deploy_installation_log.nil?
      self.create_deploy_installation_log
    end
    @my_logger           = MyLogger.new(self.deploy_installation_log)
    @my_logger.level     = self.log_level
    @my_logger.formatter = Logger::Formatter.new
    @my_logger.datetime_format = "%Y-%m-%dT%H:%M:%S."
    return @my_logger
  end

  def log(s)
    logger.info s
  end
end