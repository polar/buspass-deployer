class SwiftEndpoint < Endpoint

  def git_repository
    installation.swift_endpoint_git_repository
  end

  def git_name
    installation.swift_endpoint_git_name
  end

  def git_refspec
    installation.swift_endpoint_git_refspec
  end

end