class DeployEndpointJobspec < DeployJobspec

  def valid?(job)
    if job && job.endpoint.nil?
      puts "No endpoint"
      return false
    end
    return true
  end
end