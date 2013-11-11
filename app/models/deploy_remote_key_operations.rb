module DeployRemoteKeyOperations

  # Requires installation to be defined

  def remote_key
    key = RemoteKey.where(:name => installation.ssh_key_name).first
    if key
      if ! File.exists?(key.ssh_key.file.path) && key.key_encrypted_content
        key.decrypt_key_content_to_file
      end
      return key.ssh_key.file.path
    end
  end
end