class DeployHerokuApiKey
  include MongoMapper::Document
  key :name
  key :key_encrypted_content

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :key_encrypted_content

  def encrypt_key_content(key_content, opts = {})
    encrypted = Encryptor.encrypt(key_content, opts)
    self.key_encrypted_content = Base64.encode64(encrypted).encode('utf-8')
  end

  def decrypt_key_content(opts = {})
    decoded = Base64.decode64(key_encrypted_content).encode('ascii-8bit')
    return Encryptor.decrypt(decoded, opts)
  end

end