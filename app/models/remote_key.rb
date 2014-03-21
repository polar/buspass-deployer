require "carrierwave"
require "carrierwave/orm/mongomapper"

class RemoteKey
  include MongoMapper::Document

  key :name
  key :key_encrypted_content

  begin
  mount_uploader :ssh_key, RemoteKeyFileUploader
  rescue NameError
  end


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

  before_validation :assign_name

  def assign_name
    self.name = ssh_key.file.filename if ssh_key.file
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

  def path
    ssh_key.file.path
  end
end