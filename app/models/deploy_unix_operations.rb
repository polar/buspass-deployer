module DeployUnixOperations

  def unix_ssh_cmd(hostport, ssh_cert, user_name, cmd)
    match = /([0-9a-zA-Z\-\._]*)(:([0-9]*))?/.match(hostport)
    host = match[1]
    port = match[3]
    cmd = "ssh -o StrictHostKeychecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null  #{"-p #{port}" if port} -i #{ssh_cert} #{user_name}@#{host} '#{cmd}'"

    return cmd
  end

  def unix_scp_cmd(hostport, ssh_cert, user_name, path, remote_path)
    match = /([0-9a-zA-Z\-\._]*)(:([0-9]*))?/.match(hostport)
    host = match[1]
    port = match[3]
    cmd = "scp -o StrictHostKeychecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null  #{"-P #{port}" if port} -i #{ssh_cert} #{path} #{user_name}@#{host}:#{remote_path}"

    return cmd
  end


end