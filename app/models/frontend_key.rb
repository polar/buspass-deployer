class FrontendKey
  include MongoMapper::Document

  belongs_to :frontend

  key :key_encrypted_content

  # We don't use CarrierWave this in Swifty and we don't need the key here (yet).
  # so if we don't have it, we don't need it.
  mount_uploader :ssh_key, FrontendKeyFileUploader if defined?(FrontendKeyFileUploader)

  def encrypt_key_content(key_content, opts = {})
    encrypted = Encryptor.encrypt(key_content, opts)
    self.key_encrypted_content = Base64.encode64(encrypted).encode('utf-8')
  end

  def decrypt_key_content(opts = {})
    decoded = Base64.decode64(key_encrypted_content).encode('ascii-8bit')
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

  class KeyFile < StringIO
    attr_accessor :original_filename
    def initialize(sanitized_file, string)
      super(string)
      @original_filename = sanitized_file.filename
    end

  end

  def decrypt_key_content_to_file(opts = {})
    ssh_key.store!(KeyFile.new(ssh_key.file, decrypt_key_content(opts)))
    File.chmod(0600, ssh_key.file.path)
  end

  def name
    ssh_key.file.filename
  end

  def path
    ssh_key.file.path
  end
end