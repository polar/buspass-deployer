class WorkerEndpoint
  include MongoMapper::Document

  key :name
  key :endpoint_type
  key :remote_name
  key :user_name # may be standard or different per endpoint.
  key :n_workers, :default => "1"
  key :status
  key :remote_status
  key :instance_status
  key :master_slug
  key :remote_configuration_literal, String
  key :git_commit, Array

  key :log_level, Integer, :default => Logger::INFO
  timestamps!

  # Worker endpoints are organized on backends because
  # backends are organized around masters within the
  # frontend.
  belongs_to :backend, :autosave => false

  one :worker_endpoint_log, :dependent => :destroy, :autosave => false
  one :worker_endpoint_remote_log, :dependent => :destroy, :autosave => false
  one :deploy_worker_endpoint_job, :dependent => :destroy, :autosave => false

  attr_accessible :name, :endpoint_type, :remote_name, :backend, :backend_id, :master_slug, :user_name, :n_workers

  validates_uniqueness_of :remote_name, :allow_nil => true
  validates_uniqueness_of :name
  validates_presence_of :backend
  validates_presence_of :endpoint_type

  before_save :log_endpoint
  after_save :log_save_backtrace

  before_destroy :destroy_app

  def remote_configuration

  end
  def remote_configuration=

  end
  def destroy_app
    if deploy_worker_endpoint_job
      deploy_worker_endpoint_job.destroy_remote_endpoint
    end
  end

  def log_endpoint
    if persisted?
      begin
        @endpoint = WorkerEndpoint.find(self.id)
        if git_commit != @endpoint.git_commit
          if git_commit_changed?
            # don't worry about it.
            @endpoint = nil
          else
            raise Exception
          end
        end
      rescue Exception => boom
        if @endpoint.worker_endpoint_log
          log "Before Save #{Time.now}"
        end
        boom.backtrace.each do |line|
          log line.to_s
        end
      end
    end
  end

  def log_save_backtrace
    raise Exception
  rescue Exception => boom
    if @endpoint && @endpoint.worker_endpoint_log
      @endpoint.log "On Save #{updated_at}"
    end
  end

  def installation
    backend.frontend.installation
  end

  def frontend
    backend.frontend
  end

  def job_status
    deploy_worker_endpoint_job.get_status if deploy_worker_endpoint_job
  end

  def git_repository
    installation.worker_endpoint_git_repository
  end

  def git_name
    installation.worker_endpoint_git_name
  end

  def git_refspec
    installation.worker_endpoint_git_refspec
  end

  def self.new_instance_for_backend(backend, endpoint_type = "Heroku")
    name = backend.master_slug || backend.host
    count = backend.worker_endpoints.count
    remote_name = "busme-w#{count}-#{name.gsub(".","-")}"[0..29]
    endpoint = WorkerEndpoint.new(:name => remote_name,
                                 :endpoint_type => endpoint_type,
                                 :remote_name => remote_name,
                                 :master_slug => backend.master_slug,
                                 :backend => backend)
    ucount = 0
    while !endpoint.valid? && ucount < 26 do
      u = "abcdefghijklmnopqrstuvwxyz"[ucount]
      remote_name = "busme-w#{u}#{count}-#{name.gsub(".", "-")}"[0..29]
      endpoint = WorkerEndpoint.new(:name => remote_name,
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
    if self.worker_endpoint_log.nil?
      self.create_worker_endpoint_log
    end
    @my_logger           = MyLogger.new(self.worker_endpoint_log)
    @my_logger.level     = self.log_level
    @my_logger.formatter = Logger::Formatter.new
    @my_logger.datetime_format = "%Y-%m-%dT%H:%M:%S."
    return @my_logger
  end

  def log(s)
    logger.info s
  end

end