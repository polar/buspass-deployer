class WorkerEndpoint1 < Endpoint
  include HerokuEndpointImpl
  include UnixEndpointImpl

  def self.new_instance(attributes)
    swift = self.new(attributes)
    case swift.deployment_type
      when "Heroku"
      when "Unix"
              swift.user_name = "busme"
              swift.uadmin_name = "uadmin"
              swift.start_comand = "script/worker_start"
              swift.stop_command = "script/worker_stop"
              swift.restart_command = "script/worker_restart"
    end
    return swift
  end

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