class WorkerEndpoint < Endpoint

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