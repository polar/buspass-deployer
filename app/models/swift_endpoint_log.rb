class SwiftEndpointLog < Logger::LogDevice
  include MongoMapper::Document

  key :log_content, Array, :default => []

  belongs_to :swift_endpoint, :autosave => false

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