class DeployBackendJobspec  < DeployJobspec

  def valid?(job)
    if job.nil? || job.backend.nil?
      puts "No Backend"
      return false
    end
    return true
  end

end
