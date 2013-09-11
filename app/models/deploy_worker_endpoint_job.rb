require "open3"

module HerokuHeadless
  def self.reset
    @@heroku = nil
  end
end

class DeployWorkerEndpointJob
  include MongoMapper::Document

  belongs_to :worker_endpoint, :autosave => false

  
  key :status_content
  attr_accessible :worker_endpoint, :worker_endpoint_id

  def set_status(s)
    self.status_content = s
    save
    worker_endpoint.status = s
    worker_endpoint.save
    log("status: #{s}")
  end

  def get_status
    status_content
  end

  def log(s)
    worker_endpoint.log(s)
  end

  def user_name
    worker_endpoint.user_name
  end
  
  def app_name
    worker_endpoint.remote_name
  end

  def app_type
    worker_endpoint.endpoint_type
  end

  def backend
    worker_endpoint.backend
  end

  def frontend
    backend.frontend
  end

  def installation
    frontend.installation
  end

  def ssh_cert
    if frontend.frontend_key
      if ! File.exists?(frontend.frontend_key.ssh_key.file.path) && frontend.frontend_key.key_encrypted_content
        frontend.frontend_key.decrypt_key_content_to_file
      end
      return frontend.frontend_key.ssh_key.file.path
    end
  end

  def pub_cert(cert_path)
    file = Tempfile.new("cert.pub")
    Rush.bash("ssh-keygen -y -f #{cert_path} > #{file.path}")
    return file
  end

  def delayed_jobs
    Delayed::Job.where(:queue => "deploy-web", :failed_at => nil).select do |job|
      job.payload_object.is_a?(DeployWorkerEndpointJobspec) && job.payload_object.deploy_worker_endpoint_job_id == self.id
    end
  end

  def reset_api
    # We have to reset, because successive connection/SSL failures
    # do not resolve themselves. Ugg.
    HerokuHeadless.reset
    HerokuHeadless.configure do |config|
      config.pre_deploy_git_commands = [
          "script/dist-config \"#{worker_endpoint.git_repository}\" \"#{worker_endpoint.git_name}\" \"#{worker_endpoint.git_refspec}\" /tmp"
      ]
      config.force_push = true
      config.repository_location = File.join("/", "tmp", worker_endpoint.git_name)
    end
  end

  def unix_ssh_cmd(cmd)
    match = /([0-9a-zA-Z\-\._]*)(:([0-9]*))?/.match(app_name)
    host = match[1]
    port = match[3]
    cmd = "ssh -o StrictHostKeychecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null  #{"-p #{port}" if port} -i #{ssh_cert} #{user_name}@#{host} '#{cmd}'"

    log "Remote: #{cmd}"
    return cmd
  end

  def uadmin_unix_ssh_cmd(cmd)
    match = /([0-9a-zA-Z\-\._]*)(:([0-9]*))?/.match(app_name)
    host = match[1]
    port = match[3]
    cmd = "ssh -o StrictHostKeychecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null  #{"-p #{port}" if port} -i #{ssh_cert} uadmin@#{host} '#{cmd}'"

    log "Remote: #{cmd}"
    return cmd
  end

  def unix_scp_cmd(path, remote_path)
    match = /([0-9a-zA-Z\-\._]*)(:([0-9]*))?/.match(app_name)
    host = match[1]
    port = match[3]
    cmd = "scp -o StrictHostKeychecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null  #{"-P #{port}" if port} -i #{ssh_cert} #{path} #{user_name}@#{host}:#{remote_path}"

    log "Remote: #{cmd}"
    return cmd
  end

  def uadmin_unix_scp_cmd(path, remote_path)
    match = /([0-9a-zA-Z\-\._]*)(:([0-9]*))?/.match(app_name)
    host = match[1]
    port = match[3]
    cmd = "scp -o StrictHostKeychecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null  #{"-P #{port}" if port} -i #{ssh_cert} #{path} uadmin@#{host}:#{remote_path}"

    log "Remote: #{cmd}"
    return cmd
  end

  def create_remote_endpoint
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    case worker_endpoint.endpoint_type
      when "Heroku"
        begin
          set_status("Creating")
          result = HerokuHeadless.heroku.post_app(:name => app_name)
          worker_endpoint.reload
          set_status("Success:Create")
          return true
        rescue Exception => boom
          log "#{head}: error Heroku.post_app(:name => #{app_name}) -- #{boom}"
          worker_endpoint.reload
          set_status("Error:Create")
          return nil
        end
      when "Unix"
        begin
          set_status("Creating")
          log "#{head}: Creating Unix Endpoint #{user_name}@#{app_name}. Should already exist!"
          #result = Rush.bash uadmin_unix_ssh_cmd("sudo addgroup --quiet busme; exit 0")
          result = Rush.bash uadmin_unix_ssh_cmd("sudo adduser #{user_name} --quiet --disabled-password || exit 0")
          log "#{head}: Result #{result.inspect}"
          #result = Rush.bash uadmin_unix_ssh_cmd("sudo adduser --quiet #{user_name} busme; exit 0")
          result = Rush.bash uadmin_unix_ssh_cmd("sudo -u #{user_name} mkdir -p ~#{user_name}/.ssh")
          log "#{head}: Result #{result.inspect}"
          result = Rush.bash uadmin_unix_ssh_cmd("sudo -u #{user_name} chmod 777 ~#{user_name}/.ssh")
          log "#{head}: Result #{result.inspect}"
          file = pub_cert(ssh_cert)
          result = Rush.bash uadmin_unix_scp_cmd(file.path, "~#{user_name}/.ssh/worker_endpoint.pub")
          log "#{head}: Result #{result.inspect}"
          file.unlink
          result = Rush.bash uadmin_unix_ssh_cmd("cat ~#{user_name}/.ssh/worker_endpoint.pub | sudo -u #{user_name} tee -a ~#{user_name}/.ssh/authorized_keys")
          result = Rush.bash uadmin_unix_ssh_cmd("sudo chown -R #{user_name}:#{user_name} ~#{user_name}")
          log "#{head}: Result #{result.inspect}"
          result = Rush.bash uadmin_unix_ssh_cmd("sudo -u #{user_name} chmod 700 ~#{user_name}/.ssh")
          log "#{head}: Result #{result.inspect}"
          result = Rush.bash unix_ssh_cmd("ls -la")
          worker_endpoint.reload
          log "#{head}: remote worker endpoint #{user_name}@#{app_name} exists."
          log "#{head}: Result #{result.inspect}"
          set_status("Success:Create")
          return true
        rescue Exception => boom
          log "#{head}: error creating ~#{user_name} on remote server - #{boom}"
          set_status("Error:Create")
          return nil
        end
      else
        worker_endpoint.reload
        set_status("Error:Create")
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def get_deploy_status
    head = __method__
    log "#{head}: START"
    set_status("DeployStatus")
    worker_endpoint.reload
    case worker_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Getting deploy worker endpoint #{app_name} status."
          result = HerokuHeadless.heroku.get_releases(app_name)
          log "#{head}: Result #{result} status."
          if result
            release = result.data[:body].select {|x| x["commit"]}.last
            if release
              Rush.bash("script/dist-config \"#{worker_endpoint.git_repository}\" \"#{worker_endpoint.git_name}\" \"#{worker_endpoint.git_refspec}\" /tmp")
              log "#{head}: Release #{release.inspect}"
              commit = [ "#{release["name"]} #{release["descr"]} created_at #{release["created_at"]} by #{release["user"]}"]
              commit += Rush.bash("cd \"/tmp/#{worker_endpoint.git_name}\"; git log --max-count=1 `git rev-parse #{release["commit"]}`").split("\n").take(3)
              commit += ["#{worker_endpoint.git_repository} #{worker_endpoint.git_refspec}"]

              commit += Rush.bash("cd \"/tmp/#{worker_endpoint.git_name}\"; git log --max-count=1 `git rev-parse #{worker_endpoint.git_refspec}`").split("\n").take(3)
              worker_endpoint.reload
              worker_endpoint.git_commit = commit
              set_status("Success:DeployStatus")
              log "#{head}: Worker endpoint #{app_name} - #{worker_endpoint.git_commit.inspect} - updated_at #{worker_endpoint.updated_at}"
            else
              worker_endpoint.reload
              set_status("Error:DeployStatus")
              log "#{head}: No commit releases"
            end
          else
            set_status("Error:DeployStatus")
            status = ["Not Created"]
            worker_endpoint.reload
            worker_endpoint.remote_status = status
            worker_endpoint.save
            return status.inspect
          end
        rescue Heroku::API::Errors::NotFound => boom
          set_status("Error:DeployStatus")
          log "#{head}: remote worker endpoint #{app_name} does not exist."
          return nil
        end
      when "Unix"
        begin
          log "#{head}: Getting deploy worker endpoint #{user_name}@#{app_name} status."
          result = Rush.bash unix_ssh_cmd("cd buspass-workers; git log | head -3")
          worker_endpoint.reload
          worker_endpoint.git_commit = result
          worker_endpoint.save
          set_status("Success:DeployStatus")
          log "#{head}: Worker endpoint #{app_name} - #{worker_endpoint.git_commit.inspect} - updated_at #{worker_endpoint.updated_at}"
        rescue Exception => boom
          log "#{head}: Error getting Worker endpoint #{app_name} deploy status - #{boom}"
          set_status("Error:DeployStatus")
          status = ["Could not get status"]
          worker_endpoint.remote_status = status
          worker_endpoint.save
          return status.inspect
        end
      else
        set_status("Error:DeployStatus")
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def remote_endpoint_exists?
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    case worker_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Checking if remote worker endpoint #{app_name} exists."
          result = HerokuHeadless.heroku.get_app(app_name)
          worker_endpoint.reload
          log "#{head}: remote worker endpoint #{app_name} exists."
          if result
            log "#{head}: remote worker endpoint #{app_name} exists."
            return true
          else
            log "#{head}: remote worker endpoint #{app_name} does not exist."
            return false
          end
        rescue Heroku::API::Errors::NotFound => boom
          log "remote worker endpoint #{app_name} does not exist."
          return false
        end
      when "Unix"
        begin
          # Created in this sense means I can log on with the proper credentials.
          log "#{head}: Checking if remote worker endpoint #{user_name}@#{app_name} exists!"
          result = Rush.bash unix_ssh_cmd("ls ~#{user_name}")
          log "#{head}: Result - #{result.inspect}."
          worker_endpoint.reload
          log "#{head}: remote worker endpoint #{user_name}@#{app_name} exists."
          set_status("Success:Exists")
          return true
        rescue Exception => boom
          log "#{head}: error ssh to remote server #{boom}"
          log "#{head}: remote worker endpoint #{user_name}@#{app_name} does not exist."
          set_status("Error:Exists")
          return false
        end
      else
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def remote_endpoint_status
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    set_status("RemoteStatus")
    case worker_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Getting remote worker endpoint #{app_name} status."
          result = HerokuHeadless.heroku.get_app(app_name)
          if result
            result = HerokuHeadless.heroku.get_ps(app_name)
            worker_endpoint.reload
            if result && result.data && result.data[:body]
              log "#{head}: status is #{result.data[:body].inspect}"
              status = result.data[:body].map {|s| "#{s["process"]}: #{s["pretty_state"]}" }
              status = ["DOWN"] if status.length == 0
              worker_endpoint.reload
              worker_endpoint.remote_status = status
              worker_endpoint.save
              set_status("Success:RemoteStatus")
              get_deploy_status
              return result.data[:body].inspect
            else
              worker_endpoint.reload
              worker_endpoint.remote_status = ["Not Available"]
              worker_endpoint.save
              set_status("Error:RemoteStatus")
              log "#{head}: remote worker endpoint #{app_name} bad status."
              return nil
            end
          else
            worker_endpoint.reload
            set_status("Error:RemoteStatus")
            status = ["Not Created"]
            worker_endpoint.remote_status = status
            worker_endpoint.save
            return status.inspect
          end
        rescue Heroku::API::Errors::NotFound => boom
          worker_endpoint.reload
          set_status("Error:RemoteStatus")
          log "#{head}: remote worker endpoint #{app_name} does not exist."
          return nil
        end
      when "Unix"
        log "#{head}: Getting Remote Status of Unix Endpoint #{user_name}@#{app_name}."
        result = Rush.bash unix_ssh_cmd("ls -l buspass-workers/tmp/pids")
        log "#{head}: Result - #{result.inspect}."
        worker_endpoint.reload
        if result
          worker_endpoint.remote_status = result.is_a?(Array) ? result : result.split("\n").drop(1)
          worker_endpoint.save
          set_status("Success:RemoteStatus")
        else
          worker_endpoint.remote_status = ["No PIDs"]
          worker_endpoint.save
          set_status("Error:RemoteStatus")
        end
      else
        worker_endpoint.reload
        set_status("Error:RemoteStatus")
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def start_remote_endpoint
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    set_status("Starting")
    case worker_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Starting remote worker endpoint #{app_name}."
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "fork", 1)
          worker_endpoint.reload
          if result && result.data && result.data[:body]
            set_status("Success:Start")
            log "status is #{result.data[:body].inspect}"
            return result.data[:body].inspect
          else
            set_status("Error:Start")
            log "#{head}: remote worker endpoint #{app_name} bad result."
            return nil
          end
        rescue Heroku::API::Errors::NotFound => boom
          worker_endpoint.reload
          set_status("Error:Start")
          log "#{head}: remote worker endpoint #{app_name} does not exist."
          return nil
        end
      when "Unix"
        begin
          log "#{head}: Starting remote worker endpoint #{user_name}@#{app_name}."
          result = Rush.bash unix_ssh_cmd('bash --login -c "source ~/buspass-workers.env; cd buspass-workers; bundle exec script/instance -e production --daemonize"')
          log "#{head}: Result - #{result.inspect}."
          worker_endpoint.reload
          set_status("Success:Start")
          return result.inspect
        rescue Exception => boom
          worker_endpoint.reload
          set_status("Error:Start")
          log "#{head}: error in starting worker endpoint #{user_name}@#{app_name} - #{boom}."
          return nil
        end
      else
        worker_endpoint.reload
        set_status("Error:Start")
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def restart_remote_endpoint
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    set_status("Restarting")
    case worker_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Restarting remote worker endpoint #{app_name}."
          result = HerokuHeadless.heroku.post_ps_restart(app_name)
          worker_endpoint.reload
          if result && result.data && result.data[:body]
            set_status("Success:Restart")
            log "status is #{result.data[:body].inspect}"
            return result.data[:body].inspect
          else
            set_status("Error:Restart")
            log "#{head}: remote worker endpoint #{app_name} bad result."
            return nil
          end
        rescue Heroku::API::Errors::NotFound => boom
          worker_endpoint.reload
          set_status("Error:Restart")
          log "#{head}: remote worker endpoint #{app_name} does not exist."
          return nil
        end
      when "Unix"
        begin
          log "#{head}: Restarting remote worker endpoint #{user_name}@#{app_name}."
          result = Rush.bash unix_ssh_cmd('bash --login -c "source ~/buspass-workers.env; cd buspass-workers; bundle exec script/stop_instances -e production"')
          log "#{head}: Result - #{result.inspect}."
          result = Rush.bash unix_ssh_cmd('bash --login -c "source ~/buspass-workers.env; cd buspass-workers; bundle exec script/instance -e production --daemonize"')
          log "#{head}: Result - #{result.inspect}."
          worker_endpoint.reload
          set_status("Success:Restart")
          log "status is #{result.inspect}"
          return result
        rescue Exception => boom
          log "#{head}: error restarting worker endpoint #{app_name} - #{boom}."
          worker_endpoint.reload
          set_status("Error:Restart")
          log "#{head}: remote worker endpoint #{app_name} does not exist."
          return nil
        end
      else
        worker_endpoint.reload
        set_status("Error:Restart")
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def stop_remote_endpoint
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    set_status("Stopping")
    case worker_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Stopping remote worker endpoint #{app_name}."
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "web", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "work", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "fork", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "rake", 0)
          worker_endpoint.reload
          if result && result.data && result.data[:body]
            set_status("Success:Stop")
            log "status is #{result.data[:body].inspect}"
            return result.data[:body].inspect
          else
            set_status("Error:Stop")
            log "#{head}: remote worker endpoint #{app_name} bad result."
            return nil
          end
        rescue Heroku::API::Errors::NotFound => boom
          worker_endpoint.reload
          set_status("Error:Stop")
          log "#{head}: remote worker endpoint #{app_name} does not exist."
          return nil
        end
      when "Unix"
        begin
          log "#{head}: Stopping remote worker endpoint #{user_name}@#{app_name}."
          result = Rush.bash unix_ssh_cmd('bash --login -c "source ~/buspass-workers.env; cd buspass-workers; bundle exec script/stop_instances -e production"')
          log "#{head}: Result - #{result.inspect}."
          worker_endpoint.reload
          set_status("Success:Stop")
          log "status is #{result.inspect}"
          return true
        rescue Exception => boom
          worker_endpoint.reload
          set_status("Error:Stop")
          log "#{head}: Error stopping worker endpoint #{user_name}@#{app_name} - #{boom}"
        end
      else
        worker_endpoint.reload
        set_status("Error:Stop")
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def configure_remote_endpoint
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    set_status("Configuring")
    case worker_endpoint.endpoint_type
      when "Heroku"
        begin
          vars = {
              "INSTALLATION" => installation.name,
              "FRONTEND" => frontend.name,
              "BACKEND" => backend.name,
              "WORKER_ENDPOINT" => worker_endpoint.name,
              "HEROKU_API_KEY" => ENV['HEROKU_API_KEY'],
              "AWS_ACCESS_KEY_ID" => ENV['AWS_ACCESS_KEY_ID'],
              "AWS_SECRET_ACCESS_KEY" => ENV['AWS_SECRET_ACCESS_KEY'],
              "S3_BUCKET_NAME" => ENV['S3_BUCKET_NAME'],
              "FOG_PROVIDER" => ENV['FOG_PROVIDER'],
              "FOG_DIRECTORY" => ENV['FOG_DIRECTORY'],
              "ASSET_DIRECTORY" => ENV['ASSET_DIRECTORY'],
              "ASSET_HOST" => ENV['ASSET_HOST'],
              "MONGOLAB_URI" => ENV['MONGOLAB_URI'],
              "INTERCOM_APPID" => ENV['INTERCOM_APPID'],
              "BUSME_BASEHOST" => ENV["BUSME_BASEHOST"],
              "SWIFTIPLY_KEY" => ENV['SWIFTIPLY_KEY'],
              "N_SERVERS" => worker_endpoint.n_workers,
              "SSH_KEY" => ENV['SSH_KEY'],
              "MASTER_SLUG" => backend.master_slug
          }
          log "#{head}: Setting configuration variables for worker endpoint #{app_name}."
          result = HerokuHeadless.heroku.put_config_vars(app_name, vars)
          worker_endpoint.reload
          if result && result.data[:body]
            log "#{head}: Configuration Result #{result.inspect}"
            vars_set = result.data[:body].keys
            log "#{head}: Remote Configuration Variables #{vars_set.join(", ")} have been set for worker endpoint #{app_name}."
            set_status("Success:Configure")
          else
            set_status("Error:Configure")
          end
          return result
        rescue Exception => boom
          worker_endpoint.reload
          log "#{head}: Cannot configure worker endpoint #{app_name} - #{boom}"
          set_status("Error:Configure")
          return nil
        end
      when "Unix"
        begin
          vars = {
              "INSTALLATION" => installation.name,
              "FRONTEND" => frontend.name,
              "BACKEND" => backend.name,
              "WORKER_ENDPOINT" => worker_endpoint.name,
              "HEROKU_API_KEY" => ENV['HEROKU_API_KEY'],
              "AWS_ACCESS_KEY_ID" => ENV['AWS_ACCESS_KEY_ID'],
              "AWS_SECRET_ACCESS_KEY" => ENV['AWS_SECRET_ACCESS_KEY'],
              "S3_BUCKET_NAME" => ENV['S3_BUCKET_NAME'],
              "FOG_PROVIDER" => ENV['FOG_PROVIDER'],
              "FOG_DIRECTORY" => ENV['FOG_DIRECTORY'],
              "ASSET_DIRECTORY" => ENV['ASSET_DIRECTORY'],
              "ASSET_HOST" => ENV['ASSET_HOST'],
              "MONGOLAB_URI" => ENV['MONGOLAB_URI'],
              "INTERCOM_APPID" => ENV['INTERCOM_APPID'],
              "BUSME_BASEHOST" => ENV["BUSME_BASEHOST"],
              "SWIFTIPLY_KEY" => ENV['SWIFTIPLY_KEY'],
              "RAILS_ENV" => ENV['RAILS_ENV'], # should be 'production'
              "N_SERVERS" => worker_endpoint.n_workers,
              "SSH_KEY" => ENV['SSH_KEY'],
              "MASTER_SLUG" => backend.master_slug
          }
          log "#{head}: Setting configuration variables for worker endpoint #{user_name}@#{app_name}."
          file = Tempfile.new('vars')
          vars.each_pair do |k,v|
            file.write("export #{k}='#{v}'\n")
          end
          file.close
          result = Rush.bash unix_scp_cmd(file.path, ".buspass-workers.env")
          file.unlink
          log "#{head}: Configuration Result #{result.inspect}"
          worker_endpoint.reload
          worker_endpoint.status = result
          worker_endpoint.save
          set_status("Success:Configure")
        rescue Exception => boom
          worker_endpoint.reload
          log "#{head}: Cannot configure worker endpoint #{app_name} - #{boom}"
          set_status("Error:ConfigureRemoteEndpoint")
          return nil
        end
      else
        worker_endpoint.reload
        set_status("Error:Configure")
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def deploy_to_remote_endpoint
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    set_status("Deploying")
    case worker_endpoint.endpoint_type
      when "Heroku"
        begin
          HerokuHeadless::Deployer.logger = self
          log "#{head}: Deploying #{app_name} refspec #{worker_endpoint.git_refspec}."
          result = HerokuHeadless::Deployer.deploy(app_name, worker_endpoint.git_refspec)
          worker_endpoint.reload
          if result
            log "#{head}: Created worker endpoint #{app_name} - #{result.inspect}"
            set_status("Success:Deployed")
            HerokuHeadless.heroku.post_ps_scale(app_name, "web", 0)
            get_deploy_status
            return result
          else
            set_status("Error:Deploy")
            return nil
          end
        rescue Exception => boom
          log "#{head}: Could not deploy worker endpoint to #{worker_endpoint.endpoint_type} #{app_name} : #{boom}"
          set_status("Error:Deploy")
          return nil
        end
      when "Unix"
        begin
          log "#{head}: Deploying worker endpoint #{user_name}@#{app_name}"
          result = Rush.bash unix_ssh_cmd('test -e buspass-workers && test -e buspass-workers/script/stop_instances && bash --login -c "source ~/.buspass-workers.env; cd buspass-workers; bundle exec script/stop_instances -e production" || exit 0')
          log "#{head}: Result - #{result.inspect}."
          result = Rush.bash unix_ssh_cmd("test -e buspass-workers || git clone http://github.com/polar/buspass-workers.git -b #{worker_endpoint.git_refspec}")
          log "#{head}: Result - #{result.inspect}."
          result = Rush.bash unix_ssh_cmd("cd buspass-workers; git pull; git submodule init; git submodule update")
          log "#{head}: Result - #{result.inspect}."
          result = Rush.bash unix_ssh_cmd('bash --login -c "cd buspass-workers; bundle install"')
          log "#{head}: Result - #{result.inspect}."
          worker_endpoint.reload
          log "#{head}: Created worker endpoint #{app_name} - #{result.inspect}"
          set_status("Success:Deployed")
          get_deploy_status
        rescue Exception => boom
          worker_endpoint.reload
          log "#{head}: Could not deploy worker endpoint to #{worker_endpoint.endpoint_type} #{user_name}@#{app_name} : #{boom}"
          set_status("Error:Deploy")
        end
      else
        set_status("Error:Deploy")
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def destroy_remote_endpoint
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    set_status("Deleting")
    case worker_endpoint.endpoint_type
      when "Heroku"
        begin
          log "Deleting worker endpoint #{app_name}"
          result = HerokuHeadless.heroku.delete_app(app_name)
          worker_endpoint.reload
          set_status("Success:Delete")
          return result
        rescue Exception => boom
          worker_endpoint.reload
          log "#{head}: Could not delete worker endpoint #{worker_endpoint.endpoint_type} #{app_name} : #{boom}"
          set_status("Error:Delete")
          return nil
        end
      when "Unix"
        begin
          log "Deleting worker endpoint #{user_name}@#{app_name}"
          stop_remote_endpoint
          result = Rush.bash unix_ssh_cmd("rm -rf buspass-workers")
          result = Rush.bash uadmin_unix_ssh_cmd("test `ls ~#{user_name} | wc -l` == '0' && sudo deluser --remove-home #{user_name}")
          log "#{head}: Result - #{result.inspect}."
          worker_endpoint.reload
          set_status("Success:DestroyApp")
          return result
        rescue Exception => boom
          worker_endpoint.reload
          log "#{head}: Could not delete worker endpoint #{worker_endpoint.endpoint_type} #{user_name}@#{app_name} : #{boom}"
          set_status("Error:DestroyApp")
          return nil
        end
      else
        worker_endpoint.reload
        set_status("Error:Delete")
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  # This is a job to destroy the worker endpoint and the backend
  def destroy_worker_endpoint
    destroy_remote_endpoint
    worker_endpoint.destroy
    # in turn this object should be destroyed.
  end

  def logs_remote_endpoint
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    set_status("Logs")
    case worker_endpoint.endpoint_type
      when "Heroku"
        begin
          log "Logs #{app_name}"
          result = HerokuHeadless.heroku.get_logs(app_name, :num => 500)
          worker_endpoint.reload
          if result && result.status == 200
            log "#{head}: Log available at #{result.data[:body]}"
            if worker_endpoint.worker_endpoint_remote_log.nil?
              worker_endpoint.create_worker_endpoint_remote_log
            end
            worker_endpoint.worker_endpoint_remote_log.clear
            data = open(result.data[:body]).readlines.each do |line|
              worker_endpoint.worker_endpoint_remote_log.write(line)
            end
            set_status("Success:Logs")
            return result.data[:body]
          else
            worker_endpoint.reload
            set_status("Error:Logs")
            return nil
          end
        rescue Exception => boom
          worker_endpoint.reload
          log "#{head}: Could not get remote logs for #{worker_endpoint.endpoint_type} #{user_name}@#{app_name} : #{boom}"
          set_status("Error:Logs")
          return nil
        end
      when "Unix"
        begin
          log "Logs Unix WorkerEndpoint #{user_name}@#{app_name}"
          result = Rush.bash unix_ssh_cmd("tail -500 buspass-workers/log/production.log")
          if worker_endpoint.worker_endpoint_remote_log.nil?
            worker_endpoint.create_worker_endpoint_remote_log
          end
          worker_endpoint.worker_endpoint_remote_log.clear
          result.split("\n").each do |line|
            worker_endpoint.worker_endpoint_remote_log.write(line)
          end
          set_status("Success:GetLogs")
          return result
        rescue Exception => boom
          worker_endpoint.reload
          log "#{head}: Could not get remote logs for #{worker_endpoint.endpoint_type} #{user_name}@#{app_name} : #{boom}"
          set_status("Error:Logs")
          return nil
        end
      else
        worker_endpoint.reload
        set_status("Error:Logs")
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def truncate_logs_remote_endpoint
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    set_status("TruncateLogs")
    case worker_endpoint.endpoint_type
      when "Heroku"
        # do nothing
        worker_endpoint.reload
        log "#{head} No need to truncate logs for Heroku"
        set_status("Success:TruncateLogs")
      when "Unix"
        begin
          log "Truncate Logs of #{user_name}@#{app_name}"
          result = Rush.bash unix_ssh_cmd("truncate --size '<1M' --no-create buspass-workers/log/*.log")
          worker_endpoint.reload
          log "#{head}: Result - #{result}"
          set_status("Success:TruncateLogs")
        rescue Exception => boom
          log "#{head}: error truncating logs for #{user_name}@#{app_name} - #{boom}"
        end
      else
        log "#{head}: Unknown Endpoint type #{worker_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def job_create_and_deploy_remote_endpoint
    head = __method__
    log "#{head}: START"
    worker_endpoint.reload
    result = remote_endpoint_exists?
    result = create_remote_endpoint if not result
    result = configure_remote_endpoint if result
    result = deploy_to_remote_endpoint if result
    result = start_remote_endpoint if result
    return result
  ensure
    log "#{head}: DONE"
  end

end