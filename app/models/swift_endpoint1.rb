class SwiftEndpoint1 < Endpoint
  include HerokuEndpointImpl
  include UnixEndpointImpl

  def self.new_instance(attributes)
    swift = self.new(attributes)
    case swift.deployment_type
      when "Heroku"
      when "Unix"
              swift.user_name = "busme"
              swift.uadmin_name = "uadmin"
              swift.start_comand = "script/swift_start"
              swift.stop_command = "script/swift_stop"
              swift.restart_command = "script/swift_restart"
    end
    return swift
  end

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