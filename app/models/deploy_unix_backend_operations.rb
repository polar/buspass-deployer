module DeployUnixBackendOperations
  include DeployUnixOperations
  include DeployRemoteKeyOperations
  
  # Requires Endpoint of the Unix subtype
  
  def remote_user
    backend.remote_user
  end

  def admin_user
    backend.admin_user
  end
  
  def remote_host
    backend.frontend.remote_host
  end

  def remote_key
    installation.remote_key
  end

  def git_name
    backend.frontend.git_name
  end

  def name
    backend.name
  end

  def ruby_version
    "1.9.3"
  end
  
  def uadmin_unix_ssh(cmd)
    log "#{admin_user}@#{remote_host}: #{cmd}"
    result = Rush.bash unix_ssh_cmd(remote_host, ssh_cert, admin_user, cmd)
    if result
      result.split("\n").each do |line|
        log "#{admin_user}@#{remote_host}: #{line}"
      end
    else
      log "#{admin_user}@#{remote_host}: no result!"
    end
    return result
  end

  def uadmin_unix_scp(path, remote_path)
    log "#{admin_user}@#{remote_host}: scp #{path} #{remote_path}"
    result = Rush.bash unix_scp_cmd(remote_host, ssh_cert, admin_user, path, remote_path)
    if result
      result.split("\n").each do |line|
        log "#{admin_user}@#{remote_host}: #{line}"
      end
    else
      log "#{admin_user}@#{remote_host}: no result!"
    end
    return result
  end

  def unix_ssh(cmd)
    log "#{remote_user}@#{remote_host}: #{cmd}"
    result = Rush.bash unix_ssh_cmd(remote_host, ssh_cert, remote_user, cmd)
    if result
      result.split("\n").each do |line|
        log "#{remote_user}@#{remote_host}: #{line}"
      end
    else
      log "#{remote_user}@#{remote_host}: no result!"
    end
    return result
  end

  def unix_scp(path, remote_path)
    log "#{remote_user}@#{remote_host}: scp #{path} #{remote_path}"
    result = Rush.bash unix_scp_cmd(remote_host, ssh_cert, remote_user, path, remote_path)
    if result
      result.split("\n").each do |line|
        log "#{remote_user}@#{remote_host}: #{line}"
      end
    else
      log "#{remote_user}@#{remote_host}: no result!"
    end
    return result
  end

end