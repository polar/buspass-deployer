class SwiftEndpoint
  include MongoMapper::Document

  key :name
  key :endpoint_type
  key :remote_name
  key :status
  key :remote_status
  key :instance_status
  key :master_slug
  key :git_commit, Array

  key :log_level, Integer, :default => Logger::INFO

  belongs_to :backend

  one :swift_endpoint_log, :dependent => :destroy
  one :swift_endpoint_remote_log, :dependent => :destroy
  one :deploy_swift_endpoint_job, :dependent => :destroy

  attr_accessible :name, :endpoint_type, :remote_name, :backend, :backend_id, :master_slug

  validates_uniqueness_of :remote_name, :allow_nil => true
  validates_uniqueness_of :name
  validates_presence_of :backend
  validates_presence_of :endpoint_type

  def installation
    backend.frontend.installation
  end

  def job_status
    deploy_swift_endpoint_job.get_status if deploy_swift_endpoint_job
  end

  def git_repository
    installation.swift_endpoint_git_repository
  end

  def git_name
    installation.swift_endpoint_git_name
  end

  def git_refspec
    installation.swift_endpoint_git_refspec
  end

  def self.new_instance_for_backend(backend, endpoint_type = "Heroku")
    name = backend.master_slug || backend.host
    count = backend.swift_endpoints.count
    remote_name = "busme-#{count}-#{name.gsub(".", "-")}"[0..32]
    endpoint = SwiftEndpoint.new(:name => remote_name,
                                 :endpoint_type => endpoint_type,
                                 :remote_name => remote_name,
                                 :master_slug => backend.master_slug,
                                 :backend => backend)
    ucount = 0
    while !endpoint.valid? && ucount < 26 do
      u = "ABCDEFGHIJKLMNOPQUSTUVWXYZ"[ucount]
      remote_name = "busme-#{u}#{count}-#{name}"[0..32]
      endpoint = SwiftEndpoint.new(:name => remote_name,
                                   :endpoint_type => endpoint_type,
                                   :remote_name => remote_name,
                                   :master_slug => backend.master_slug,
                                   :backend => backend)
      ucount += 1
    end
    if !endpoint.valid?
      if endpoint.errors.include?(:remote_name) && !endpoint.remote_name.nil?
        endpoint.remote_name = nil # will let Heroku decide
      end
      if endpoint.errors.include?(:name)
        endpoint.name = endpoint.id.to_s
      end
    end
    return endpoint
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
    if self.swift_endpoint_log.nil?
      self.create_swift_endpoint_log
    end
    @my_logger           = MyLogger.new(self.swift_endpoint_log)
    @my_logger.level     = self.log_level
    @my_logger.formatter = Logger::Formatter.new
    @my_logger.datetime_format = "%Y-%m-%dT%H:%M:%S."
    return @my_logger
  end

  def log(s)
    logger.info s
  end

end