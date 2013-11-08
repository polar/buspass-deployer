class ServerEndpoint1 < Endpoint
  include HerokuEndpointImpl
  include UnixEndpointImpl

  def self.new_instance(attributes)
    swift = self.new(attributes)
    case swift.deployment_type
      when "Heroku"
      when "Unix"
              swift.user_name = "busme"
              swift.uadmin_name = "uadmin"
              swift.start_comand = "script/server_start"
              swift.stop_command = "script/server_stop"
              swift.restart_command = "script/server_restart"
    end
    return swift
  end

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