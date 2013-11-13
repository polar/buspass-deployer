class WorkerEndpoint < Endpoint

  validates_presence_of :remote_user, :if => lambda { ["Unix"].include? deployment_type }
  validates_presence_of :remote_host, :if => lambda { ["Unix"].include? deployment_type }

  def git_repository
    installation.worker_endpoint_git_repository
  end

  def git_name
    installation.worker_endpoint_git_name
  end

  def git_refspec
    installation.worker_endpoint_git_refspec
  end

end