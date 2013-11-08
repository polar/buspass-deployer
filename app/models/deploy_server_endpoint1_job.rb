class DeployServerEndpoint1Job < DeployEndpointJob

  def self.new_instance(attributes)
    job = self.new(attributes)
    case job.endpoint.deployment_type
      when "Heroku"
        job.singleton_class.send(:include, DeployHerokuEndpointJobImpl)
      when "Unix"
        job.singleton_class.send(:include, DeployUnixEndpointJobImpl)
    end
    job
  end

  def gen_jobspec(action)
    DeploySeverEndpointJobspec.new(id, name, action)
  end
end