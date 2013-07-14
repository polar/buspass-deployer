class DeployFrontendJob
  include MongoMapper::Document

  belongs_to :delayed_job, :class_name => "Delayed::Job", :dependent => :destroy
  one :frontend

  key :status_content

  def ssh_cert
    if frontend.frontend_key
      if ! File.exists?(frontend.frontend_key.ssh_key.file.path) && frontend.frontend_key.key_encrypted_content
         frontend.frontend_key.decrypt_key_content_to_file
      end
      return frontend.frontend_key.ssh_key.file.path
    end
  end

  def set_status(s)
    begin
      reload
    rescue
    end
    self.status_content = s
    save
    log("status: #{s}")
  end

  def get_status
    status_content
  end

  def log(s)
    frontend.log s
  end

  def install_remote_frontend
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} git clone -b backends git://github.com/polar/busme-swifty.git \\&\\& cd busme-swifty \\&\\& sudo bash install.sh"
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def upgrade_remote_frontend
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/upgrade_frontend.sh  --name #{frontend.name}"
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def configure_remote_frontend_backends
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/configure_frontend_backends.sh --name '#{frontend.name}'"
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def configure_remote_frontend
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/configure_frontend.sh --name '#{frontend.name}'"
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def deconfigure_remote_frontend
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/deconfigure_frontend.sh --name '#{frontend.name}'"
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def configure_remote_backend(backend)
    head = "#{__method__}(#{backend ? backend.name : ''})"
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        if frontend.configured
          if frontend.backends.include?(backend)
            cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/configure_backend.sh --name '#{backend.name}'"
            log "#{head}: #{cmd}"
            Open3.popen2e(cmd) do |stdin,out,wait_thr|
              pid = wait_thr.pid
              out.each {|line| log("#{head}: #{line}")}
            end
          else
            log "#{head}: Backend #{backend.name} doesn't belong to Frontend #{frontend.name}."
          end
        else
          log "#{head}: Frontend #{frontend.name} is not configured."
        end
    end
    log "#{head}: DONE"
  end

  def deconfigure_remote_backend(backend)
    head = "#{__method__}(#{backend ? backend.name : ''})"
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        if frontend.backends.include?(backend)
          cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/deconfigure_backend.sh --name '#{backend.name}'"
          log "#{head}: #{cmd}"
          Open3.popen2e(cmd) do |stdin,out,wait_thr|
            pid = wait_thr.pid
            out.each {|line| log("#{head}: #{line}")}
          end
        else
          log "#{head}: Backend #{backend.name} is not in Frontend #{frontend.name}."
        end
    end
    log "#{head}: DONE"
  end

  def status_remote_frontend
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/status_frontend.sh --name '#{frontend.name}'"
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def start_remote_frontend
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/start_frontend.sh --name '#{frontend.name}'"
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def stop_remote_frontend
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/stop_frontend.sh --name '#{frontend.name}'"
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def restart_remote_frontend
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/restart_frontend.sh --name '#{frontend.name}'"
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def start_remote_backend(backend)
    head = "#{__method__}(#{backend ? backend.name : ''})"
    log "#{head}: START"
    if frontend.backends.include?(backend)
      case frontend.host_type
        when "ec2"
          cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/start_backend.sh --name '#{backend.name}'"
          log "#{head}: #{cmd}"
          Open3.popen2e(cmd) do |stdin,out,wait_thr|
            pid = wait_thr.pid
            out.each {|line| log("#{head}: #{line}")}
          end
      end
    end
    log "#{head}: DONE"
  end

  def stop_remote_backend(backend)
    head = "#{__method__}(#{backend ? backend.name : ''})"
    log "#{head}: START"
    if frontend.backends.include?(backend)
      case frontend.host_type
        when "ec2"
          cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/stop_backend.sh --name '#{backend.name}'"
          log "#{head}: #{cmd}"
          Open3.popen2e(cmd) do |stdin,out,wait_thr|
            pid = wait_thr.pid
            out.each {|line| log("#{head}: #{line}")}
          end
      end
    end
    log "#{head}: DONE"
  end

  def stop_remote_backends
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/stop_backends.sh --name '#{frontend.name}'"
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def start_remote_backends
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = "ssh -i #{ssh_cert} ec2-user@#{frontend.host} busme-swifty/scripts/start_backends.sh --name '#{frontend.name}'"
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def create_all_endpoint_apps
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        for be in frontend.backends do
          begin
            if be.deploy_backend_job.nil?
              be.create_deploy_backend_job
            end
            be.deploy_backend_job.create_endpoint_apps
          rescue Exception => boom
            log "#{head}: Error creating endpoint apps for backend #{be.name} - #{boom}"
          end
        end
    end
  ensure
    log "#{head}: DONE"
  end

  def configure_all_endpoint_apps
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        for be in frontend.backends do
          begin
            if be.deploy_backend_job.nil?
              be.create_deploy_backend_job
            end
            be.deploy_backend_job.configure_endpoint_apps
          rescue Exception => boom
            log "#{head}: Error creating endpoint apps for backend #{be.name} - #{boom}"
          end
        end
    end
  ensure
    log "#{head}: DONE"
  end

  def start_all_endpoint_apps
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        for be in frontend.backends do
          begin
            if be.deploy_backend_job.nil?
              be.create_deploy_backend_job
            end
            be.deploy_backend_job.start_endpoint_apps
          rescue Exception => boom
            log "#{head}: Error creating endpoint apps for backend #{be.name} - #{boom}"
          end
        end
    end
  ensure
    log "#{head}: DONE"
  end

  def stop_all_endpoint_apps
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        for be in frontend.backends do
          begin
            if be.deploy_backend_job.nil?
              be.create_deploy_backend_job
            end
            be.deploy_backend_job.stop_endpoint_apps
          rescue Exception => boom
            log "#{head}: Error creating endpoint apps for backend #{be.name} - #{boom}"
          end
        end
    end
  ensure
    log "#{head}: DONE"
  end

  def deploy_all_endpoint_apps
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        for be in frontend.backends do
          begin
            if be.deploy_backend_job.nil?
              be.create_deploy_backend_job
            end
            be.deploy_backend_job.deploy_endpoint_apps
          rescue Exception => boom
            log "#{head}: Error creating endpoint apps for backend #{be.name} - #{boom}"
          end
        end
    end
  ensure
    log "#{head}: DONE"
  end

  def destroy_all_endpoint_apps
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        for be in frontend.backends do
          begin
            if be.deploy_backend_job.nil?
              be.create_deploy_backend_job
            end
            be.deploy_backend_job.destroy_endpoint_apps
          rescue Exception => boom
            log "#{head}: Error creating endpoint apps for backend #{be.name} - #{boom}"
          end
        end
    end
  ensure
    log "#{head}: DONE"
  end


end