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

  def installation
    frontend.installation
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

  def create_remote_endpoint
    head = __method__
    log "#{head}: START"
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          set_status("Creating")
          result = HerokuHeadless.heroku.post_app(:name => app_name)
          set_status("Success:Create")
        rescue Exception => boom
          swift_enpoint.set_status("Error:Create")
          set_status("Error:Create")
          return nil
        end
      else
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def remote_endpoint_exists?
    head = __method__
    log "#{head}: START"
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Checking if remote swift endpoint #{app_name} exists."
          result = HerokuHeadless.heroku.get_app(app_name)
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
      else
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def remote_endpoint_status
    head = __method__
    log "#{head}: START"
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
              swift_endpoint.remote_status = status
              swift_endpoint.save
              set_status("Success:RemoteStatus")
              return result.data[:body].inspect
            else
              swift_endpoint.remote_status = ["Not Available"]
              swift_endpoint.save
              set_status("Error:RemoteStatus")
              log "#{head}: remote swift endpoint #{app_name} bad status."
              return nil
            end
          else
            set_status("Error:RemoteStatus")
            status = ["Not Created"]
            swift_endpoint.remote_status = status
            swift_endpoint.save
            return status.inspect
          end
        rescue Heroku::API::Errors::NotFound => boom
          set_status("Error:RemoteStatus")
          log "#{head}: remote swift endpoint #{app_name} does not exist."
          return nil
        end
      else
        set_status("Error:RemoteStatus")
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def start_remote_endpoint
    head = __method__
    log "#{head}: START"
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Starting remote swift endpoint #{app_name}."
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "web", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "work", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "swift", 1)
          if result && result.data && result.data[:body]
            log "status is #{result.data[:body].inspect}"
            return result.data[:body].inspect
          else
            log "#{head}: remote swift endpoint #{app_name} bad result."
            return nil
          end
        rescue Heroku::API::Errors::NotFound => boom
          log "#{head}: remote swift endpoint #{app_name} does not exist."
          return nil
        end
      else
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def stop_remote_endpoint
    head = __method__
    log "#{head}: START"
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Stopping remote swift endpoint #{app_name}."
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "web", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "work", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "swift", 0)
          if result && result.data && result.data[:body]
            log "status is #{result.data[:body].inspect}"
            return result.data[:body].inspect
          else
            log "#{head}: remote swift endpoint #{app_name} bad result."
            return nil
          end
        rescue Heroku::API::Errors::NotFound => boom
          log "#{head}: remote swift endpoint #{app_name} does not exist."
          return nil
        end
      else
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def restart_remote_endpoint
    head = __method__
    log "#{head}: START"
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "#{head}: Restarting remote swift endpoint #{app_name}."
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "work", 0)
          result = HerokuHeadless.heroku.post_ps_scale(app_name, "work", 1)
          if result && result.data && result.data[:body]
            log "status is #{result.data[:body].inspect}"
            return result.data[:body].inspect
          else
            log "#{head}: remote swift endpoint #{app_name} bad result."
            return nil
          end
        rescue Heroku::API::Errors::NotFound => boom
          log "#{head}: remote swift endpoint #{app_name} does not exist."
          return nil
        end
      else
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def configure_remote_endpoint
    head = __method__
    log "#{head}: START"
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
              "ASSET_HOST" => ENV['ASSET_HOST'],
              "MONGOLAB_URI" => ENV['MONGOLAB_URI'],
              "INTERCOM_APPID" => ENV['INTERCOM_APPID'],
              "BUSME_BASEHOST" => ENV["BUSME_BASEHOST"],
              "SWIFTIPLY_KEY" => ENV['SWIFTIPLY_KEY'],
              "SSH_KEY" => ENV['SSH_KEY'],
              "MASTER_SLUG" => backend.master_slug
          }
          set_status("Configuring")
          log "#{head}: Setting configuration variables for swift endpoint #{app_name}."
          result = HerokuHeadless.heroku.put_config_vars(app_name, vars)
          if result && result.data[:body]
            vars_set = result.data[:body].keys
            log "#{head}: Remote Configuration Variables #{vars_set.join(", ")} have been set for swift endpoint #{app_name}."
            set_status("Success:Configure")
          else
            set_status("Error:Configure")
          end
          return result
        rescue Exception => boom
          log "#{head}: Cannot configure swift endpoint #{app_name} - #{boom}"
          set_status("Error:Configure")
          return nil
        end
      else
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def deploy_to_remote_endpoint
    head = __method__
    log "#{head}: START"
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          set_status("Deploying")
          HerokuHeadless::Deployer.logger = self
          result = HerokuHeadless::Deployer.deploy(app_name, swift_endpoint.git_refspec)
          if result
            commit = ["#{swift_endpoint.git_repository} #{swift_endpoint.git_refspec}"]
            commit += Rush.bash("cd \"/tmp/#{swift_endpoint.git_name}\"; git log --max-count=1 `git rev-parse #{swift_endpoint.git_refspec}`").split("\n").take(3)
            swift_endpoint.git_commit = commit
            log "#{head}: Created swift endpoint #{app_name}"
            set_status("Success:Deployed")
            HerokuHeadless.heroku.post_ps_scale(app_name, "web", 0)
            return result
          else
            set_status("Error:Deploy")
            return nil
          end
        rescue Exception => boom
          log "#{head}: Could not deploy swift endpoint to #{swift_endpoint.endpoint_type} #{app_name} : #{boom}"
          set_status("Error:Deploy")
          return nil
        end
      else
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def destroy_remote_endpoint
    head = __method__
    log "#{head}: START"
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "Deleting swift endpoint #{app_name}"
          set_status("Deleting")
          result = HerokuHeadless.heroku.delete_app(app_name)
          set_status("Success:Deleted")
          return result
        rescue Exception => boom
          log "#{head}: Could not delete swift endpoint #{swift_endpoint.endpoint_type} #{app_name} : #{boom}"
          set_status("Error:Delete")
          return nil
        end
      else
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def logs_remote_endpoint
    head = __method__
    log "#{head}: START"
    case swift_endpoint.endpoint_type
      when "Heroku"
        begin
          log "Deleting #{app_name}"
          set_status("GettingLogs")
          result = HerokuHeadless.heroku.get_logs(app_name, :num => 500)
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
            return nil
          end
        rescue Exception => boom
          log "#{head}: Could not get remote logs for #{swift_endpoint.endpoint_type} #{app_name} : #{boom}"
          set_status("Error:GetLogs")
          return nil
        end
      else
        log "#{head}: Unknown Endpoint type #{swift_endpoint.endpoint_type}"
    end
  ensure
    log "#{head}: DONE"
  end

  def job_create_and_deploy_remote_endpoint
    head = __method__
    log "#{head}: START"
    result = remote_endpoint_exists?
    result = create_remote_endpoint if not result
    result = configure_remote_endpoint if result
    result = deploy_to_remote_endpoint if result
    return result
  ensure
    log "#{head}: DONE"
  end

end