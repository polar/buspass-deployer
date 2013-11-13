class DeployServerEndpointJob < DeployEndpointJob

  def self.get_job(endpoint, action)
    job = self.where(:endpoint_id => endpoint.id).first
    if job.nil?
      job = DeployServerEndpointJob.new(:endpoint => endpoint)
      job.save
    end
    DeployServerEndpointJobspec.new(job.id, action, endpoint.name)
  end

end