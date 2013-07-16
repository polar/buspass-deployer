require "open3"

module HerokuHeadless
  def self.reset
    @@heroku = nil
  end
end

class DeployWebrunnerJob
  include MongoMapper::Document

  belongs_to :delayed_job, :class_name => "Delayed::Job", :dependent => :destroy
  belongs_to :web_runner

  key :status_content
  key :log_content, Array

  attr_accessible :web_runner, :web_runner_id

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
    puts s
    msg = Time.now.strftime("%Y-%m-%dT%H:%M:%S.") + " " + s
    push(:log_content => msg)
  end

  def to_a()
    reload
    log_content
  end

  def segment(i, n)
    log_content.drop(i).take(n)
  end

  def app_name
    web_runner.app_name
  end

  def backend
    web_runner.backend
  end

  def reset_api
    # We have to reset, because successive connection/SSL failures
    # do not resolve themselves. Ugg.
    HerokuHeadless.reset
    HerokuHeadless.configure do |config|
      config.pre_deploy_git_commands = [
          "script/dist-config"
      ]
    end
  end

  def create_remote_runner
    web_runner.set_status("Creating")
    set_status("Creating")
    result = HerokuHeadless.heroku.post_app(:name => app_name)
    web_runner.set_status("Success:Create")
    set_status("Success:Create")
  rescue Exception => boom
    web_runner.set_status("Error:Create")
    set_status("Error:Create")
    return nil
  end

  def remote_runner_exists?
    log "checking if remote runner #{app_name} exists."
    result = HerokuHeadless.heroku.get_app(app_name)
    log "remote runner #{app_name} exists."
    if result
      log "remote runner #{app_name} exists."
      return true
    else
      log "remote runner #{app_name} does not exist."
      return false
    end
  rescue Heroku::API::Errors::NotFound => boom
    log "remote runner #{app_name} does not exist."
    return false
  end

  def remote_runner_status
    log "Getting remote runner #{app_name} status."
    result = HerokuHeadless.heroku.get_ps(app_name)
    if result && result.data && result.data[:body]
      log "status is #{result.data[:body].inspect}"
      return result.data[:body].inspect
    else
      log "remote runner #{app_name} bad status."
      return nil
    end
  rescue Heroku::API::Errors::NotFound => boom
    log "remote runner #{app_name} does not exist."
    return nil
  end

  def start_remote_runner
    log "Starting remote runner #{app_name}."
    result = HerokuHeadless.heroku.post_ps_scale(app_name, "work", 1)
    if result && result.data && result.data[:body]
      log "status is #{result.data[:body].inspect}"
      return result.data[:body].inspect
    else
      log "remote runner #{app_name} bad result."
      return nil
    end
  rescue Heroku::API::Errors::NotFound => boom
    log "remote runner #{app_name} does not exist."
    return nil
  end

  def configure_remote_runner
    vars = {
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
    web_runner.set_status("Configuring")
    set_status("Configuring")
    log "Setting configuration variables."
    result = HerokuHeadless.heroku.put_config_vars(app_name, vars)
    log "Remote Configuration Variables are set"
    return result
  rescue Exception => boom
    log "Cannot configure #{app_name} - #{boom}"
    web_runner.set_status("Error:Configure")
    set_status("Error:Configure")
    return nil
  end

  def deploy_to_remote_runner
    web_runner.set_status("Deploying")
    set_status("Deploying")
    HerokuHeadless::Deployer.logger = self
    result = HerokuHeadless::Deployer.deploy(app_name)
    if result
      log "Created Front End"
      web_runner.set_status("Success:Deployed")
      set_status("Success:Deployed")
      return result
    else
      web_runner.set_status("Error:Deploy")
      set_status("Error:Deploy")
      return nil
    end
  rescue Exception => boom
    log "Could not deploy WebRunner to Heroku #{app_name} : #{boom}"
    web_runner.set_status("Error:Deploy")
    set_status("Error:Deploy")
    return nil
  end

  def destroy_remote_runner
    log "Deleting #{app_name}"
    web_runner.set_status("Deleting")
    set_status("Deleting")
    result = HerokuHeadless.heroku.delete_app(app_name)
    web_runner.set_status("Success:Deleted")
    set_status("Success:Deleted")
      return result
  rescue Exception => boom
    log "Could not delete Heroku #{app_name} : #{boom}"
    web_runner.set_status("Error:Delete")
    set_status("Error:Delete")
    return nil
  end

  def job_create_and_deploy_remote_runner
    result = remote_runner_exists?
    result = create_remote_runner if not result
    result = configure_remote_runner if result
    result = deploy_to_remote_runner if result
  end

end