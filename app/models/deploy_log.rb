class DeployLog < Logger::LogDevice
  include MongoMapper::Document

  key :log_content, Array, :default => []

  one :deploy_state, :autosave => false

  def write(msg)
    push(:log_content => msg)
  end

  def close()
    # do nothing.
  end

  def clear()
    self.log_content = []
    save
  end

  def to_a()
    reload
    log_content
  end

  def segment(i, n)
    reload
    log_content.drop(i).take(n)
  end
end