class FrontendKey
  include MongoMapper::Document

  belongs_to :frontend

  key :key_encrypted_content

  mount_uploader :ssh_key, FrontendKeyFileUploader

  def encrypt_key_content(key_content, opts = {})
    encrypted = Encryptor.encrypt(key_content, opts)
    self.key_encrypted_content = Base64.encode64(encrypted).encode('utf-8')
  end

  def decrypt_key_content(opts = {})
    decoded = Base64.decode64(encoded.encode('ascii-8bit'))
    return Encryptor.decrypt(decoded, opts)
  end

  def exists?
    !key_encrypted_content.nil? || ssh_key.file.exists?
  end

  after_save :ensure_chmod

  def ensure_chmod
    if ssh_key.file.exists?
      File.chmod(0600, ssh_key.file.path)
    end
  end

  def decrypt_key_content_to_file(opts = {})
    ssh_key.store!(StringIO.new(decrypt_key_content(opts)))
    File.chmod(0600, ssh_key.file.path)
  end

  def name
    ssh_key.file.filename
  end

  def path
    ssh_key.file.path
  end
end