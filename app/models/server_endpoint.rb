class ServerEndpoint < Endpoint

  def git_repository
    installation.server_endpoint_git_repository
  end

  def git_name
    installation.server_endpoint_git_name
  end

  def git_refspec
    installation.server_endpoint_git_refspec
  end
end