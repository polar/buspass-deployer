class DeployFrontendJobspec < DeployJobspec

  def valid?(job)
    if job.nil? || job.frontend.nil?
      puts "No Frontend"
      return false
    end
    return true
  end

end
