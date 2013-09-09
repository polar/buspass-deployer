require "open3"

module HerokuHeadless
  def self.reset
    @@heroku = nil
  end
end

class DeploySwiftEndpointJob
  include MongoMapper::Document

  belongs_to :swift_endpoint


  key :status_content
  attr_accessible :swift_endpoint, :swift_endpoint_id

  def set_status(s)
    self.status_content = s
    save
    swift_endpoint.status = s
    swift_endpoint.save
    log("status: #{s}")
  end

  def get_status
    status_content
  end

  def log(s)
    swift_endpoint.log(s)
  end

  def user_name
    swift_endpoint.user_name
  end

  def app_name
    swift_endpoint.remote_name
  end

  def app_type
    swift_endpoint.endpoint_type
  end

  def backend
    swift_endpoint.backend
  end

  def frontend
    backend.frontend
  end

  def ssh_cert
    if frontend.frontend_key
      if ! File.exists?(frontend.frontend_key.ssh_key.file.path) && frontend.frontend_key.key_encrypted_content
        frontend.frontend_key.decrypt_key_content_to_file
      end
      return frontend.frontend_key.ssh_key.file.path
    end
  end

  def installation
    frontend.installation
  end

  def delayed_jobs
    Delayed::Job.where(:queue => "deploy-web", :failed_at => nil).select do |job|
      job.payload_object.is_a?(DeploySwiftEndpointJobspec) && job.payload_object.deploy_swift_endpoint_job_id == self.id
    end
  end

  def reset_api
    # We have to reset, because successive connection/SSL failures
    # do not resolve themselves. Ugg.
    HerokuHeadless.reset
    HerokuHeadless.configure do |config|
      config.pre_deploy_git_commands = [
          "script/dist-config \"#{swift_endpoint.git_repository}\" \"#{swift_endpoint.git_name}\" \"#{swift_endpoint.git_refspec}\" /tmp"
      ]
      config.repository_location = File.join("/", "tmp", swift_endpoint.git_name)
    end
  end

  def unix_ssh_cmd(cmd)
    match = /([0-9a-zA-Z\-\._]*)(:([0-9]*))?/.match(swift_endpoint.remote_name)
    host = match[1]
    port = match[3]
    cmd = "ssh -o StrictHostKeychecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null  #{"-p #{port}" if port} -i #{ssh_cert} #{user_name}@#{host} #{cmd}"

    log "Remote: #{cmd}"
    return cmd
  end

  def unix_scp_cmd(path, remote_path)
    match = /([0-9a-zA-Z\-\._]*)(:([0-9]*))?/.match(swift_endpoint.remote_name)
    host = match[1]
    port = match[3]
    cmd = "scp -o StrictHostKeychecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null  #{"-P #{port}" if port} -i #{ssh_cert} #{path} #{user_name}@#{host}:#{remote_path}"

    log "Remote: #{cmd}"
    return cmd
  end

  def create_remote_endpoint
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          result = HerokuHeadless.heroku.post_app(:name => app_name)
          swift_endpoint.reload
          set_status("Success:Create")
        rescue Exception => boom
          log "#{head}: error Heroku.post_app(:name => #{app_name}) -- #{boom}"
          set_status("Error:Create")
          return nil
        end
      when "Unix"
        begin
          log "#{head}: Creating Unix Endpoint #{user_name}@#{app_name}. Should already exist!"
          result = unix_ssh_cmd("ls /etc/passwd")
          swift_endpoint.reload
          if result
            log "#{head}: remote swift endpoint #{user_name}@#{app_name} exists."
            set_status("Success:Create")
            return result
          else
            set_status("Error:Create")
            return nil
          end
        rescue Exception => boom
          log "#{head}: error ssh to remote server #{boom}"
          set_status("Error:Create")
          return nil
        end
      else
        set_status("Error:Create")
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def remote_endpoint_exists?
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Checking if remote swift endpoint #{app_name} exists."
          result = HerokuHeadless.heroku.get_app(app_name)
          swift_endpoint.reload
          log "#{head}: remote swift endpoint #{app_name} exists."
          if result
            log "#{head}: remote swift endpoint #{app_name} exists."
            return true
          else
            log "#{head}: remote swift endpoint #{app_name} does not exist."
            return false
          end
        rescue Heroku::API::Errors::NotFound => boom
          log "remote swift endpoint #{app_name} does not exist."
          return false
        end
      when "Unix"
        begin
          log "#{head}: Checking if remote swift endpoint #{user_name}@#{app_name} exists!"
          result = unix_ssh_cmd("ls /etc/motd")
          swift_endpoint.reload
          if result
            log "#{head}: remote swift endpoint #{user_name}@#{app_name} exists."
            set_status("Success:Exists")
            return true
          else
            log "#{head}: remote swift endpoint #{user_name}@#{app_name} does not exist."
            set_status("Error:Exists")
            return false
          end
        rescue Exception => boom
          log "#{head}: error ssh to remote server #{boom}"
          log "#{head}: remote swift endpoint #{user_name}@#{app_name} does not exist."
          set_status("Error:Exists")
          return false
        end
      else
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def get_deploy_status
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
    set_status("DeployStatus")
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Getting deploy swift endpoint #{app_name} status."
          result = HerokuHeadless.heroku.get_releases(app_name)
          log "#{head}: Result #{result} status."
          if result
            release = result.data[:body].select {|x| x["commit"]}.last
            if release
              Rush.bash("script/dist-config \"#{swift_endpoint.git_repository}\" \"#{swift_endpoint.git_name}\" \"#{swift_endpoint.git_refspec}\" /tmp")
              log "#{head}: Release #{release.inspect}"
              commit = [ "#{release["name"]} #{release["descr"]} created_at #{release["created_at"]} by #{release["user"]}"]
              commit += Rush.bash("cd \"/tmp/#{swift_endpoint.git_name}\"; git log --max-count=1 `git rev-parse #{release["commit"]}`").split("\n").take(3)
              swift_endpoint.git_commit = commit
              commit += ["#{swift_endpoint.git_repository} #{swift_endpoint.git_refspec}"]

              commit += Rush.bash("cd \"/tmp/#{swift_endpoint.git_name}\"; git log --max-count=1 `git rev-parse #{swift_endpoint.git_refspec}`").split("\n").take(3)
              swift_endpoint.reload
              swift_endpoint.git_commit = commit
              set_status("Success:DeployStatus")
              log "#{head}: Swift endpoint #{app_name} - #{swift_endpoint.git_commit.inspect} - updated_at #{swift_endpoint.updated_at}"
            else
              swift_endpoint.reload
              set_status("Error:DeployStatus")
              log "#{head}: No commit releases"
            end
          else
            swift_endpoint.reload
            set_status("Error:DeployStatus")
            status = ["Not Created"]
            swift_endpoint.remote_status = status
            swift_endpoint.save
            return status.inspect
          end
        rescue Heroku::API::Errors::NotFound => boom
          swift_endpoint.reload
          set_status("Error:DeployStatus")
          log "#{head}: remote swift endpoint #{app_name} does not exist."
          return nil
        end
      when "Unix"
        log "#{head}: Getting deploy swift endpoint #{user_name}@#{app_name} status."
        result = unix_ssh_cmd("cd buspass-web; git log | head -1")
        swift_endpoint.reload
        match = /commit\s*([0-9a-f]*)/.match(result)
        if match && match[1]
          swift_endpoint.git_commit = match[1]
          swift_endpoint.save
          set_status("Success:DeployStatus")
          log "#{head}: Swift endpoint #{app_name} - #{swift_endpoint.git_commit.inspect} - updated_at #{swift_endpoint.updated_at}"
        else
          log "#{head}: Swift endpoint #{app_name} - #{swift_endpoint.git_commit.inspect} - updated_at #{swift_endpoint.updated_at}"
          set_status("Error:DeployStatus")
          status = ["Not Created"]
          swift_endpoint.remote_status = status
          swift_endpoint.save
          return status.inspect
        end
      else
        swift_endpoint.reload
        set_status("Error:DeployStatus")
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
      end
    ensure
    log "#{head}: DONE"
  end

  def remote_endpoint_status
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
    set_status("RemoteStatus")
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Getting remote swift endpoint #{app_name} status."
          result = HerokuHeadless.heroku.get_app(app_name)
          if result
            result = HerokuHeadless.heroku.get_ps(app_name)
            if result && result.data && result.data[:body]
              log "#{head}: status is #{result.data[:body].inspect}"
              status = result.data[:body].map {|s| "#{s["process"]}: #{s["pretty_state"]}" }
              status = ["DOWN"] if status.length == 0
              swift_endpoint.reload
              swift_endpoint.remote_status = status
              swift_endpoint.save
              set_status("Success:RemoteStatus")
              get_deploy_status
              return result.data[:body].inspect
            else
              swift_endpoint.reload
              swift_endpoint.remote_status = ["Not Available"]
              swift_endpoint.save
              set_status("Error:RemoteStatus")
              log "#{head}: remote swift endpoint #{app_name} bad status."
              return nil
            end
          else
            swift_endpoint.reload
            set_status("Error:RemoteStatus")
            status = ["Not Created"]
            swift_endpoint.remote_status = status
            swift_endpoint.save
            return status.inspect
          end
        rescue Heroku::API::Errors::NotFound => boom
          swift_endpoint.reload
          set_status("Error:RemoteStatus")
          log "#{head}: remote swift endpoint #{app_name} does not exist."
          return nil
        end
      when "Unix"
        log "#{head}: Getting Remote Status of Unix Endpoint #{user_name}@#{app_name}."
        result = unix_ssh_cmd("ls buspass-web/tmp/pids")
        swift_endpoint.reload
        if result
          swift_endpoint.remote_status = result
          swift_endpoint.save
          set_status("Success:RemoteStatus")
        else
          swift_endpoint.remote_status = ["No PIDs"]
          swift_endpoint.save
          set_status("Error:RemoteStatus")
        end
      else
        swift_endpoint.reload
        set_status("Error:RemoteStatus")
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def start_remote_endpoint
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
    set_status("Start")
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Starting remote swift endpoint #{app_name}."
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "web", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "work", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "swift", 1)
          swift_endpoint.reload
          if result && result.data && result.data[:body]
            set_status("Success:Start")
            log "status is #{result.data[:body].inspect}"
            return result.data[:body].inspect
          else
            set_status("Error:Start")
            log "#{head}: remote swift endpoint #{app_name} bad result."
            return nil
          end
        rescue Heroku::API::Errors::NotFound => boom
          swift_endpoint.reload
          set_status("Error:Start")
          log "#{head}: remote swift endpoint #{app_name} does not exist."
          return nil
        end
      when "Unix"
        log "#{head}: Starting remote swift endpoint #{user_name}@#{app_name}."
        result = unix_ssh_cmd("cd buspass-web; bundle exec script/instance -e production")
        swift_endpoint.reload
        if result
          set_status("Success:Start")
          log "status is #{result.inspect}"
          return result.data[:body].inspect
        else
          set_status("Error:Start")
          log "#{head}: remote swift endpoint #{app_name} bad result."
          return nil
        end
      else
        swift_endpoint.reload
        set_status("Error:Start")
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def stop_remote_endpoint
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
    set_status("Stopping")
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Stopping remote swift endpoint #{app_name}."
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "web", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "work", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "swift", 0)
          swift_endpoint.reload
          if result && result.data && result.data[:body]
            set_status("Success:Stop")
            log "status is #{result.data[:body].inspect}"
            return result.data[:body].inspect
          else
            set_status("Error:Stop")
            log "#{head}: remote swift endpoint #{app_name} bad result."
            return nil
          end
        rescue Heroku::API::Errors::NotFound => boom
          swift_endpoint.reload
          set_status("Error:Stop")
          log "#{head}: remote swift endpoint #{app_name} does not exist."
          return nil
        end
      when "Unix"
        log "#{head}: Stopping remote swift endpoint #{user_name}@#{app_name}."
        result = unix_ssh_cmd("cd buspass-web; bundle exec script/stop_instances")
        if result
          swift_endpoint.reload
          set_status("Success:Stop")
          log "status is #{result.inspect}"
        else
          set_status("Error:Stop")
          log "#{head}: remote swift endpoint #{app_name} bad result."
          return nil
        end

      else
        swift_endpoint.reload
        set_status("Error:Stop")
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def restart_remote_endpoint
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
    set_status("Restarting")
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Restarting remote swift endpoint #{app_name}."
          result = HerokuHeadless.heroku.post_ps_restart(app_name)
          swift_endpoint.reload
          if result && result.data && result.data[:body]
            set_status("Success:Restart")
            log "status is #{result.data[:body].inspect}"
            return result.data[:body].inspect
          else
            set_status("Error:Restart")
            log "#{head}: remote swift endpoint #{app_name} bad result."
            return nil
          end
        rescue Heroku::API::Errors::NotFound => boom
          swift_endpoint.reload
          set_status("Error:Restart")
          log "#{head}: remote swift endpoint #{app_name} does not exist."
          return nil
        end
      when "Unix"
        begin
          log "#{head}: Restarting remote swift endpoint #{user_name}@#{app_name}."
          result = unix_ssh_cmd("cd buspass-web; bundle exec script/stop_instances")
          result = unix_ssh_cmd("cd buspass-web; bundle exec script/instance -e production")
          swift_endpoint.reload
          if result && result
            set_status("Success:Restart")
            log "status is #{result.inspect}"
            return result
          else
            set_status("Error:Restart")
            log "#{head}: remote swift endpoint #{app_name} bad result."
            return nil
          end
        rescue Exception => boom
          swift_endpoint.reload
          set_status("Error:Restart")
          log "#{head}: remote swift endpoint #{app_name} does not exist."
          return nil
        end

      else
        swift_endpoint.reload
        set_status("Error:Restart")
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def configure_remote_endpoint
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
    set_status("Configuring")
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          vars = {
              "INSTALLATION" => installation.name,
              "FRONTEND" => frontend.name,
              "BACKEND" => backend.name,
              "SWIFT_ENDPOINT" => swift_endpoint.name,
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
              "N_SERVERS" => swift_endpoint.n_servers,
              "SSH_KEY" => ENV['SSH_KEY'],
              "MASTER_SLUG" => backend.master_slug
          }
          log "#{head}: Setting configuration variables for swift endpoint #{app_name}."
          log "#{head}: Configuration Vars #{vars.inspect}"
          result = HerokuHeadless.heroku.put_config_vars(app_name, vars)
          swift_endpoint.reload
          if result && result.data[:body]
            log "#{head}: Configuration Result #{result.inspect}"
            vars_set = result.data[:body].keys
            log "#{head}: Remote Configuration Variables #{vars_set.join(", ")} have been set for swift endpoint #{app_name}."
            set_status("Success:Configure")
          else
            set_status("Error:Configure")
          end
          return result
        rescue Exception => boom
          swift_endpoint.reload
          log "#{head}: Cannot configure swift endpoint #{app_name} - #{boom}"
          set_status("Error:ConfigureRemoteEndpoint")
          return nil
        end
      when "Unix"
        begin
          vars = {
              "INSTALLATION" => installation.name,
              "FRONTEND" => frontend.name,
              "BACKEND" => backend.name,
              "SWIFT_ENDPOINT" => swift_endpoint.name,
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
              "N_SERVERS" => swift_endpoint.n_servers,
              "SSH_KEY" => ENV['SSH_KEY'],
              "MASTER_SLUG" => backend.master_slug
          }
          log "#{head}: Setting configuration variables for swift endpoint #{user_name}@#{app_name}."
          file = Tempfile.new('vars')
          vars.each_pair do |k,v|
            file.write("export #{k}='#{v}'\n")
          end
          file.close
          result = unix_scp_cmd(file.path, ".bash_aliases")
          file.unlink
          if result
            log "#{head}: Configuration Result #{result.inspect}"
            swift_endpoint.reload
            swift_endpoint.status = result
            swift_endpoint.save
            set_status("Success:Configure")
          else
            set_status("Error:Configure")
          end
        rescue Exception => boom
          swift_endpoint.reload
          log "#{head}: Cannot configure swift endpoint #{app_name} - #{boom}"
          set_status("Error:ConfigureRemoteEndpoint")
          return nil
        end
      else
        swift_endpoint.reload
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
        set_status("Error:ConfigureRemoteEndpoint")
    end
  ensure
    log "#{head}: DONE"
  end

  def deploy_to_remote_endpoint
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
    set_status("Deploying")
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Deploying swift endpoint #{app_name}"
          HerokuHeadless::Deployer.logger = self
          result = HerokuHeadless::Deployer.deploy(app_name, swift_endpoint.git_refspec)
          swift_endpoint.reload
          if result
            log "#{head}: Created swift endpoint #{app_name} - #{result.inspect}"
            set_status("Success:Deployed")
            HerokuHeadless.heroku.post_ps_scale(app_name, "web", 0)
            get_deploy_status
            return result
          else
            set_status("Error:Deploy")
            return nil
          end
        rescue Exception => boom
          swift_endpoint.reload
          log "#{head}: Could not deploy swift endpoint to #{swift_endpoint.endpoint_type} #{app_name} : #{boom}"
          set_status("Error:Deploy")
          return nil
        end
      when "Unix"
        begin
          log "#{head}: Deploying swift endpoint #{user_name}@#{app_name}"
          result = unix_ssh_cmd("mkdir -p busme-web; cd busme-web; git clone http://github.com/polar/buspass-web.git #{swift_endpoint.git_refspec}")
          result = unix_ssh_cmd("cd busme-web; git submodule init && git submodule update")
          swift_endpoint.reload
          if result
            log "#{head}: Created swift endpoint #{app_name} - #{result.inspect}"
            set_status("Success:Deployed")
            get_deploy_status
            return result
          else
            set_status("Error:Deploy")
            return nil
          end
        rescue Exception => boom
          swift_endpoint.reload
          log "#{head}: Could not deploy swift endpoint to #{swift_endpoint.endpoint_type} #{app_name} : #{boom}"
          set_status("Error:Deploy")
          return nil
        end
      else
        swift_endpoint.reload
        set_status("Error:Deploy")
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def destroy_remote_endpoint
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
    set_status("DeletingRemote")
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "Deleting swift endpoint #{app_name}"
          result = HerokuHeadless.heroku.delete_app(app_name)
          swift_endpoint.reload
          set_status("Success:Deleted")
          return result
        rescue Exception => boom
          swift_endpoint.reload
          log "#{head}: Could not delete swift endpoint #{swift_endpoint.endpoint_type} #{app_name} : #{boom}"
          set_status("Error:Delete")
          return nil
        end
      when "Unix"
        begin
          log "Deleting swift endpoint #{user_name}@#{app_name}"
          result = unix_ssh_cmd("rm -rf .bash_aliases buspass-web")
          swift_endpoint.reload
          set_status("Success:Deleted")
          return result
        rescue Exception => boom
          swift_endpoint.reload
          log "#{head}: Could not delete swift endpoint #{swift_endpoint.endpoint_type} #{app_name} : #{boom}"
          set_status("Error:Delete")
          return nil
        end
      else
        swift_endpoint.reload
        set_status("Error:Delete")
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  # This is a job to destroy the swift endpoint and the backend
  def destroy_swift_endpoint
    destroy_remote_endpoint
    swift_endpoint.destroy
    # in turn this object should be destroyed.
  end

  def logs_remote_endpoint
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
    set_status("GettingLogs")
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "Logs Heroku SwiftEndpoint #{app_name}"
          set_status("GettingLogs")
          result = HerokuHeadless.heroku.get_logs(app_name, :num => 500)
          swift_endpoint.reload
          if result && result.status == 200
            log "#{head}: Log available at #{result.data[:body]}"
            if swift_endpoint.swift_endpoint_remote_log.nil?
              swift_endpoint.create_swift_endpoint_remote_log
            end
            swift_endpoint.swift_endpoint_remote_log.clear
            data = open(result.data[:body]).readlines.each do |line|
              swift_endpoint.swift_endpoint_remote_log.write(line)
            end
            set_status("Success:GetLogs")
            return result.data[:body]
          else
            swift_endpoint.reload
            set_status("Error:GetLogs")
            return nil
          end
        rescue Exception => boom
          swift_endpoint.reload
          log "#{head}: Could not get remote logs for #{swift_endpoint.endpoint_type} #{app_name} : #{boom}"
          set_status("Error:GetLogs")
          return nil
        end
      when "Unix"
        log "Logs Unix SwiftEndpoint #{user_name}@#{app_name}"
        result = unix_ssh_cmd("tail -500 buspass-web/log/production.log")
        if swift_endpoint.swift_endpoint_remote_log.nil?
          swift_endpoint.create_swift_endpoint_remote_log
        end
        swift_endpoint.swift_endpoint_remote_log.clear
        result.each do |line|
          swift_endpoint.swift_endpoint_remote_log.write(line)
        end
        set_status("Success:GetLogs")
        return result
      else
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end

  ensure
    log "#{head}: DONE"
  end

  def job_create_and_deploy_remote_endpoint
    head = __method__
    log "#{head}: START"
    swift_endpoint.reload
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