class DeployState
  include MongoMapper::Document

  key :status
  key :log_level, Integer, :default => Logger::INFO
  belongs_to :deploy_log

  key :state_destroy, :default => false

  # Contains the first lines of the git commit log on the remote side.
  key :git_commit, Array
  timestamps!

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

    def clear
      @joblog.clear
    end
  end

  def logger
    if @my_logger
      @my_logger.level = self.log_level
      return @my_logger
    end
    if self.deploy_log.nil?
      self.create_deploy_log
      self.deploy_log.save
      self.save
    end
    @my_logger           = MyLogger.new(self.deploy_log)
    @my_logger.level     = self.log_level
    @my_logger.formatter = Logger::Formatter.new
    @my_logger.datetime_format = "%Y-%m-%dT%H:%M:%S."
    return @my_logger
  end

  def log(s)
    logger.info s
  end

  def destroy
    super
  end
end