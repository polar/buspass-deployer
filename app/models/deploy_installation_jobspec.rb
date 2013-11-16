class DeployInstallationJobspec < DeployJobspec

  def valid?(job)
    if job.nil? || job.installation.nil?
      puts "No Installation"
      return  false
    end
    return true
  end
end
