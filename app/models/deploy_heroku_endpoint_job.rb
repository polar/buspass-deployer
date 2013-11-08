class DeployHerokuEndpointJob < DeployEndpointJob
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
  end

  def restart_remote_endpoint
    heroku_restart_remote_endpoint
  end

  def stop_remote_endpoint
  end

  def destroy_remote_endpoint
    heroku_destroy_remote_endpoint
  end

  def get_remote_deployment_status
    heroku_get_deploy_status
  end

  def get_remote_execution_status
    heroku_remote_endpoint_status
  end

  def get_remote_instance_status
    heroku_create_remote_endpoint
  end

  def get_remote_configuration
    heroku_get_remote_configuration
  end

end