class DeployWorkerEndpointJob < DeployEndpointJob

  def self.get_job(endpoint, action)
    job = self.where(:endpoint_id => endpoint.id).first
    if job.nil?
      job = DeployWorkerEndpointJob.new(:endpoint => endpoint)
      job.save
    end
    DeployWorkerEndpointJobspec.new(job.id, action, endpoint.name)
  end

end