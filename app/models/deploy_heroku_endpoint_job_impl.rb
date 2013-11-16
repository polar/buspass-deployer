module DeployHerokuEndpointJobImpl
  include DeployHerokuOperations

  def create_remote_endpoint
    heroku_create_remote_endpoint
  end

  def configure_remote_endpoint
    heroku_configure_remote_endpoint
  end

  def deploy_to_remote_endpoint
    heroku_deploy_to_remote_endpoint
  end

  def start_remote_endpoint
    case endpoint.at_type
      when "ServerEndpoint"
        case endpoint.deployment_type
          when "Heroku"
            heroku_scale_remote_endpoint("web", 1)
            heroku_scale_remote_endpoint("work", 0)
          when "Heroku-Swift"
            heroku_scale_remote_endpoint("web", 0)
            heroku_scale_remote_endpoint("work", 1)
        end
      when "WorkerEndpoint"
        heroku_scale_remote_endpoint("web", 0)
        heroku_scale_remote_endpoint("work", 1)
    end
  end

  def restart_remote_endpoint
    heroku_restart_remote_endpoint
  end

  def stop_remote_endpoint
    case endpoint.at_type
      when "ServerEndpoint"
        case endpoint.deployment_type
          when "Heroku"
            heroku_scale_remote_endpoint("web", 0)
            heroku_scale_remote_endpoint("work", 0)
          when "Heroku-Swift"
            heroku_scale_remote_endpoint("web", 0)
            heroku_scale_remote_endpoint("work", 0)
        end
      when "WorkerEndpoint"
        heroku_scale_remote_endpoint("web", 0)
        heroku_scale_remote_endpoint("work", 0)
    end
  end

  def status_remote_endpoint
    heroku_get_deploy_status
    heroku_remote_endpoint_status
  end

  def destroy_remote_endpoint
    heroku_destroy_remote_endpoint
  end

  def get_remote_deployment_status
    heroku_get_deployment_status
  end

  def get_remote_execution_status

  end

  def get_remote_instance_status

  end

  def get_remote_configuration

  end
end