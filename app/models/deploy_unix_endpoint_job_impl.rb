module DeployUnixEndpointJobImpl
  include DeployUnixEndpointOperations

  def create_remote_endpoint
    unix_create_remote_endpoint
  end

  def configure_remote_endpoint
    unix_configure_remote_endpoint
  end

  def deploy_to_remote_endpoint
    unix_deploy_to_remote_endpoint
    unix_get_deployment_status
  end

  def start_remote_endpoint
    unix_start_remote_endpoint
  end

  def restart_remote_endpoint
    unix_restart_remote_endpoint
  end

  def stop_remote_endpoint
    unix_stop_remote_endpoint
  end

  def status_remote_endpoint
    unix_get_deployment_status
    unix_status_remote_endpoint
  end

  def destroy_remote_endpoint
    unix_destroy_remote_endpoint
  end

  def get_remote_deployment_status
    unix_get_deployment_status
  end

  def get_remote_execution_status

  end

  def get_remote_instance_status

  end

  def get_remote_configuration

  end
end