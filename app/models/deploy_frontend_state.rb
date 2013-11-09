class DeployFrontendState
  include MongoMapper::Document

  key :status
  key :remote_status
  key :instance_status
  key :log_level, Integer, :default => Logger::INFO
  timestamps!

  belongs_to :frontend, :autosave => false, :class_name => "Frontend1"
  belongs_to :frontend_log, :class_name => "Frontend1Log"

  attr_accessible :frontend, :frontend_id

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
    if self.endpoint_log.nil?
      self.create_endpoint_log
    end
    @my_logger           = MyLogger.new(self.endpoint_log)
    @my_logger.level     = self.log_level
    @my_logger.formatter = Logger::Formatter.new
    @my_logger.datetime_format = "%Y-%m-%dT%H:%M:%S."
    return @my_logger
  end

  def log(s)
    logger.info s
  end
end