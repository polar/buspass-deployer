module DeployUnixFrontendJobImpl
  include DeployUnixFrontendOperations

  def create_remote_frontend
    unix_create_remote_frontend
  end

  def configure_remote_frontend
    unix_configure_remote_frontend
  end

  def deconfigure_remote_frontend
    unix_deconfigure_remote_frontend
  end

  def deploy_to_remote_frontend
    unix_deploy_to_remote_frontend
  end

  def status_remote_frontend
    unix_status_remote_frontend
  end

  def start_remote_frontend
    unix_start_remote_frontend
  end

  def stop_remote_frontend
    unix_stop_remote_frontend
  end

  def restart_remote_frontend
    unix_restart_remote_frontend
  end

  def destroy_remote_frontend
    unix_destroy_remote_frontend
  end
end