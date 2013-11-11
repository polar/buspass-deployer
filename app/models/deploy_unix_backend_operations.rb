module DeployUnixBackendOperations
  include DeployUnixOperations
  
  # Requires Endpoint of the Unix subtype
  
  def remote_user
    backend.remote_user
  end

  def admin_user
    backend.admin_user
  end
  
  def remote_host
    backend.remote_name
  end

  def remote_key
    backend.remote_key
  end

  def name
    backend.name
  end

  def ruby_version
    "1.9.3"
  end
  
  def uadmin_unix_ssh(cmd)
    log "#{admin_user}@#{remote_host}: #{cmd}"
    result = Rush.bash unix_ssh_cmd(remote_host, remote_key, admin_user, cmd)
    log "#{admin_user}@#{remote_host}: Result #{result.inspect}"
    return result
  end

  def uadmin_unix_scp(path, remote_path)
    log "#{admin_user}@#{remote_host}: scp #{path} #{remote_path}"
    result = Rush.bash unix_scp_cmd(remote_host, remote_key, admin_user, path, remote_path)
    log "#{admin_user}@#{remote_host}: Result #{result.inspect}"
    return result
  end

  def unix_ssh(cmd)
    log "#{remote_user}@#{remote_host}: #{cmd}"
    result = Rush.bash unix_ssh_cmd(remote_host, remote_key, remote_user, cmd)
    log "#{remote_user}@#{remote_host}: Result #{result.inspect}"
    return result
  end
  
  def unix_scp(path, remote_path)
    log "#{remote_user}@#{remote_host}: scp #{path} #{remote_path}"
    result = Rush.bash unix_scp_cmd(remote_host, remote_key, remote_user, path, remote_path)
    log "#{remote_user}@#{remote_host}: Result #{result.inspect}"
    return result
  end

end