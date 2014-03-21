module DeployRemoteKeyOperations

  # Requires installation to be defined

  def ssh_cert
    key = RemoteKey.where(:name => installation.ssh_key_name).first
    if key
      if ! File.exists?(key.ssh_key.file.path) && key.key_encrypted_content
        key.decrypt_key_content_to_file(:key => ENV["SECRET_ENCRYPTION_KEY"])
      end
      return key.ssh_key.file.path
    end
  end
end