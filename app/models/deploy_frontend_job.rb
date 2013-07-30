class DeployFrontendJob
  include MongoMapper::Document

  one :frontend, :autosave => false

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

  def delayed_jobs
    Delayed::Job.where(:queue => "deploy-web", :failed_at => nil).select do |job|
      job.payload_object.is_a?(DeployFrontendJobspec) && job.payload_object.deploy_frontend_job_id == self.id
    end
  end

  def ssh_cmd(cmd)
    "ssh -o StrictHostKeychecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null -i #{ssh_cert} ec2-user@#{frontend.host} #{cmd}"
  end

  def scp_cmd(path, remote_path)
    "scp -o StrictHostKeychecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null -i #{ssh_cert} #{path} ec2-user@#{frontend.host}:#{remote_path}"
  end

  def install_remote_frontend
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = ssh_cmd "\"git clone -b #{frontend.git_refspec} #{frontend.git_repository} \\\"#{frontend.git_name}\\\" ; cd \\\"#{frontend.git_name}\\\" ; git pull; git checkout \\\"#{frontend.git_refspec}\\\" ; sudo bash install.sh \\\"#{frontend.git_name}\\\"\""
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
    end
    log "#{head}: DONE"
  end

  def full_upgrade_remote_frontend
    head = __method__
    log "#{head}: START"
    set_status("Full Upgrade #{frontend.name}")
    begin
      upgrade_remote_frontend
      configure_remote_frontend
      configure_remote_frontend_backends
      set_status("Success:FullUpgrade")
    rescue Exception => boom
      log "#{head}: Error Full Upgrade : -- #{boom}"
      set_status("Error:FullUpgrade")
    end
  ensure
    log "#{head}: DONE"
  end

  def upgrade_remote_frontend
    head = __method__
    log "#{head}: START"
    set_status("Upgrading #{frontend.name}")
    case frontend.host_type
      when "ec2"
        exit_status = nil
        cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/upgrade_frontend.sh\\\"  --name \\\"#{frontend.name}\\\""
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
          exit_status = wait_thr.value
        end
        if exit_status.exitstatus == 0
          set_status("Success:Upgrade #{frontend.name}")
        else
          # This happens if the git is already up to date.
          set_status("Error:Upgrade #{frontend.name}")
        end
        set_status("Done:Upgrade #{frontend.name}")
    end
    log "#{head}: DONE"
  end

  def frontend_busme_creds
    vars = {
        "INSTALLATION" => frontend.installation.name,
        "MONGOLAB_URI" => ENV['MONGOLAB_URI'],
        "SWIFTIPLY_KEY" => ENV['SWIFTIPLY_KEY'],
    }
    file = File.open("/tmp/busme_creds", "w+")
    vars.each_pair do |k,v|
      file.write("export #{k}='#{v}'\n")
    end
    file.close
    file
  end

  def configure_remote_frontend_backends
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/configure_frontend_backends.sh\\\" --name \\\"#{frontend.name}\\\""
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
        credsfile = frontend_busme_creds
        cmd = scp_cmd(credsfile.path, ".busme_creds")
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
        File.delete(credsfile.path)
        cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/configure_frontend.sh\\\" --name \\\"#{frontend.name}\\\""
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
        cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/deconfigure_frontend.sh\\\" --name \\\"#{frontend.name}\\\""
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
            cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/configure_backend.sh\\\" --name \\\"#{backend.name}\\\""
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
          cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/deconfigure_backend.sh\\\" --name \\\"#{backend.name}\\\""
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
    set_status("RemoteStatus")
    case frontend.host_type
      when "ec2"
        cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/status_frontend.sh\\\" --name \\\"#{frontend.name}\\\""
        log "#{head}: #{cmd}"
        Open3.popen2e(cmd) do |stdin,out,wait_thr|
          pid = wait_thr.pid
          out.each {|line| log("#{head}: #{line}")}
        end
        set_status("Done:RemoteStatus")
    end
    log "#{head}: DONE"
  end

  def start_remote_frontend
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/start_frontend.sh\\\" --name \\\"#{frontend.name}\\\""
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
        cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/stop_frontend.sh\\\" --name \\\"#{frontend.name}\\\""
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
        cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/restart_frontend.sh\\\" --name \\\"#{frontend.name}\\\""
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
          cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/start_backend.sh\\\" --name \\\"#{backend.name}\\\""
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
          cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/stop_backend.sh\\\" --name \\\"#{backend.name}\\\""
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
        cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/stop_backends.sh\\\" --name \\\"#{frontend.name}\\\""
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
        cmd = ssh_cmd "\\\"#{frontend.git_name}/scripts/start_backends.sh\\\" --name \\\"#{frontend.name}\\\""
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
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "create_swift_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "create_worker_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
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
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "configure_swift_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "configure_worker_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
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
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "start_swift_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "start_worker_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
          rescue Exception => boom
            log "#{head}: Error creating endpoint apps for backend #{be.name} - #{boom}"
          end
        end
    end
  ensure
    log "#{head}: DONE"
  end

  def restart_all_endpoint_apps
    head = __method__
    log "#{head}: START"
    case frontend.host_type
      when "ec2"
        for be in frontend.backends do
          begin
            if be.deploy_backend_job.nil?
              be.create_deploy_backend_job
            end
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "restart_swift_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "restart_worker_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
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
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "stop_swift_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "stop_worker_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
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
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "deploy_swift_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "deploy_worker_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
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
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "destroy_swift_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
            job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "destroy_worker_endpoint_apps", nil)
            Delayed::Job.enqueue(job, :queue => "deploy-web")
          rescue Exception => boom
            log "#{head}: Error creating endpoint apps for backend #{be.name} - #{boom}"
          end
        end
    end
  ensure
    log "#{head}: DONE"
  end

  def destroy_frontend
    head = __method__
    log "#{head}: START"
    deconfigure_remote_frontend
    for be in frontend.backends do
      if be.deploy_backend_job.nil?
        be.create_deploy_backend_job
      end
      job = DeployBackendJobspec.new(be.deploy_backend_job.id, be.name, "destroy_backend", nil)
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    frontend.destroy
  end


end