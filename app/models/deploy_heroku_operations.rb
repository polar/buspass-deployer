module DeployHerokuOperations

  # Requires 
  #  endpoint : Endpoint

  def heroku_app_name
    endpoint.heroku_app_name
  end

  def deploy_heroku_api_key
    DeployHerokuApiKey.find_by_name(installation.deploy_heroku_api_key_name)
  end

  def heroku_reset_api
    # We have to reset, because successive connection/SSL failures
    # do not resolve themselves. Ugg.
    HerokuHeadless.reset
    ENV["HEROKU_API_KEY"] = deploy_heroku_api_key.decrypt_key_content(:key => ENV["AWS_SECRET_ACCESS_KEY"])
    HerokuHeadless.configure do |config|
      config.pre_deploy_git_commands = [
          "script/dist-config \"#{endpoint.git_repository}\" \"#{endpoint.git_name}\" \"#{endpoint.git_refspec}\" /tmp"
      ]
      config.force_push = true
      config.repository_location = File.join("/", "tmp", endpoint.git_name)
    end
  end
  
  def heroku_create_remote_endpoint
    head = __method__
    heroku_reset_api
    set_status("Creating")
    log "#{head}: Creating #{endpoint.at_type} - #{heroku_app_name}"
    result = HerokuHeadless.heroku.post_app(:name => heroku_app_name)
    set_status("Success:Create")
    return true
  rescue Exception => boom
    log "#{head}: error Heroku.post_app(:name => #{heroku_app_name}) -- #{boom}"
    set_status("Error:Create")
    return nil
  end
  
  def heroku_get_deploy_status
    head = __method__
    log "#{head}: Getting deploy worker endpoint #{heroku_app_name} status."
    heroku_reset_api
    result = HerokuHeadless.heroku.get_releases(heroku_app_name)
    log "#{head}: Result #{result} status."
    if result
      release = result.data[:body].select {|x| x["commit"]}.last
      if release
        Rush.bash("script/dist-config \"#{endpoint.git_repository}\" \"#{endpoint.git_name}\" \"#{endpoint.git_refspec}\" /tmp")
        #log "#{head}: Release #{release.inspect}"
        commit = ["Current Remote Release"]
        commit += [ "#{release["name"]} #{release["descr"]} created_at #{release["created_at"]} by #{release["user"]}"]
        commit += Rush.bash("cd \"/tmp/#{endpoint.git_name}\"; git log --max-count=1 `git rev-parse #{release["commit"]}`").split("\n").take(3)
        commit += ["#{endpoint.git_repository} #{endpoint.git_refspec}"]

        commit += ["Latest Local Release"]
        commit += Rush.bash("cd \"/tmp/#{endpoint.git_name}\"; git log --max-count=1 `git rev-parse #{endpoint.git_refspec}`").split("\n").take(3)
        state.git_commit = commit
        state.save
        log "#{head}: #{endpoint.at_type} #{heroku_app_name}  - updated_at #{state.updated_at}"
        commit.each do |line|
          log "#{head}: #{line}"
        end
        set_status("Success:DeployStatus")
      else
        set_status("Error:DeployStatus")
        log "#{head}: No commit releases"
      end
    else
      set_status("Error:DeployStatus", ["Not Created"])
    end
  rescue Heroku::API::Errors::NotFound => boom
    set_status("Error:DeployStatus")
    log "#{head}: Remote #{endpoint.at_type} - #{heroku_app_name} does not exist."
  end
  
  def heroku_remote_endpoint_exists?
    head = __method__
    log "#{head}: Checking if Remote #{endpoint.at_type} - #{heroku_app_name} exists."
    heroku_reset_api
    result = HerokuHeadless.heroku.get_app(heroku_app_name)
    log "#{head}: Remote #{endpoint.at_type} - #{heroku_app_name} exists."
    if result
      log "#{head}: Remote #{endpoint.at_type} - #{heroku_app_name} exists."
      return true
    else
      log "#{head}: Remote #{endpoint.at_type} - #{heroku_app_name} does not exist."
      return false
    end
  rescue Heroku::API::Errors::NotFound => boom
    log "Remote #{endpoint.at_type} - #{heroku_app_name} does not exist."
    return false
  end
  
  def heroku_remote_endpoint_status
    head = __method__
    set_status("RemoteStatus")
    log "#{head}: Getting Remote #{endpoint.at_type} - #{heroku_app_name} status."
    heroku_reset_api
    result = HerokuHeadless.heroku.get_app(heroku_app_name)
    if result
      result = HerokuHeadless.heroku.get_ps(heroku_app_name)
      if result && result.data && result.data[:body]
        #log "#{head}: status is #{result.data[:body].inspect}"
        state.instance_status = []
        if endpoint.at_type == "ServerEndpoint" && endpoint.deployment_type == "Heroku"
          state.instance_status += ["#{endpoint.server_proxy.proxy_address}(#{endpoint.external_ip})"]
        end
        result.data[:body].each do |process|
          state.instance_status += ["#{process["process"]} : #{process["pretty_state"]}"]
        end
        status = state.instance_status.length > 0 ? "UP" : "DOWN"
        set_status("Success:RemoteStatus", status)
        state.instance_status.each do |line|
          log "#{head}: #{line}"
        end
      else
        set_status("Error:RemoteStatus", "Not Available")
        log "#{head}: Remote #{endpoint.at_type} #{heroku_app_name} has no status."
      end
    else
      set_status("Error:RemoteStatus", ["Not Created"])
    end
  rescue Heroku::API::Errors::NotFound => boom
    set_status("Error:RemoteStatus")
    state.instance_status = ["Not Created"]
    set_status("Success:RemoteStatus", "Not Created")
    log "#{head}: Remote #{endpoint.at_type} #{heroku_app_name} does not exist."
  rescue Exception => boom
    log "#{head}: Remote #{endpoint.at_type} #{error}."
  end
  
  def heroku_scale_remote_endpoint(proc, ndynos = 1)
    head = __method__
    set_status("ScaleRemoteEndpoint")
    heroku_reset_api
    log "#{head}: Start Remote #{endpoint.at_type} #{heroku_app_name}."
    result = HerokuHeadless.heroku.post_ps_scale(heroku_app_name, proc, ndynos)
    if result && result.data && result.data[:body]
      set_status("Success:ScaleRemoteEndpoint")
      log "status is #{result.data[:body].inspect}"
    else
      set_status("Error:ScaleRemoteEndpoint")
      log "#{head}: Remote #{endpoint.at_type} #{heroku_app_name} bad result."
    end
  rescue Heroku::API::Errors::NotFound => boom
    set_status("Error:ScaleRemoteEndpoint")
    log "#{head}: Remote #{endpoint.at_type} #{heroku_app_name} does not exist."
  rescue Exception => boom
    set_status("Error:ScaleRemoteEndpoint")
    log "#{head}: Remote #{endpoint.at_type} #{heroku_app_name} does not exist."
  end

  def heroku_restart_remote_endpoint
    head = __method__
    set_status("Restart")
    heroku_reset_api
    log "#{head}: Restarting Remote #{endpoint.at_type} #{heroku_app_name} ."
    result = HerokuHeadless.heroku.post_ps_restart(heroku_app_name)
    if result && result.data && result.data[:body]
      set_status("Success:Restart")
      log "status is #{result.data[:body].inspect}"
    else
      set_status("Error:Restart")
      log "#{head}: Remote #{endpoint.at_type} #{heroku_app_name} bad result."
    end
  rescue Heroku::API::Errors::NotFound => boom
    set_status("Error:Restart")
    log "#{head}: Remote #{endpoint.at_type} #{heroku_app_name} does not exist."
  end
  
  def heroku_configure_remote_endpoint
    head = __method__
    set_status("Configure")
    heroku_reset_api
    log "#{head}: Setting configuration variables for Remote #{endpoint.at_type} #{heroku_app_name}."
    result = HerokuHeadless.heroku.put_config_vars(heroku_app_name, endpoint.remote_configuration)
    if result && result.data[:body]
      #log "#{head}: Configuration Result #{result.inspect}"
      vars_set = result.data[:body].keys
      log "#{head}: Remote Configuration Variables #{vars_set.join(", ")} have been set for Remote #{endpoint.at_type} #{heroku_app_name}."
      set_status("Success:Configure")
    else
      set_status("Error:Configure")
    end
  rescue Exception => boom
    log "#{head}: Cannot configure Remote #{endpoint.at_type} #{heroku_app_name} - #{boom}"
    set_status("Error:Configure")
  end
  
  def heroku_deploy_to_remote_endpoint
    head = __method__
    set_status("Deploy")
    heroku_reset_api
     # The following must be self as it takes log(msg)
    HerokuHeadless::Deployer.logger = self
    log "#{head}: Deploying Remote #{endpoint.at_type} #{heroku_app_name} refspec #{endpoint.git_refspec}."
    result = HerokuHeadless::Deployer.deploy(heroku_app_name, endpoint.git_refspec)
    if result
      log "#{head}: Created Remote #{endpoint.at_type} #{heroku_app_name} - #{result.inspect}"
      set_status("Success:Deployed")
    else
      set_status("Error:Deploy")
    end
  rescue Exception => boom
    log "#{head}: Could not deploy Remote #{endpoint.at_type} #{heroku_app_name} : #{boom}"
    set_status("Error:Deploy")
  end
  
  def heroku_destroy_remote_endpoint
    head = __method__
    set_status("Destroy")
    heroku_reset_api
    log "Deleting Remote #{endpoint.at_type} #{heroku_app_name}"
    result = HerokuHeadless.heroku.delete_app(heroku_app_name)
    set_status("Success:Delete")
    return result
  rescue Exception => boom
    log "#{head}: Could not delete Remote #{endpoint.at_type} #{heroku_app_name} : #{boom}"
    set_status("Error:Delete")
  end
  
  def heroku_get_remote_endpoint_logs
    head = __method__
    set_status("GetLogs")
    heroku_reset_api
    result = HerokuHeadless.heroku.get_logs(heroku_app_name, :num => 500)
    if result && result.status == 200
      log "#{head}: Log available at #{result.data[:body]}"
      if endpoint.endpoint_remote_log.nil?
        endpoint.create_endpoint_remote_log
      end
      endpoint.endpoint_remote_log.clear
      data = open(result.data[:body]).readlines.each do |line|
        # TODO:  Move log to job
        endpoint.endpoint_remote_log.write(line)
      end
      set_status("Success:GetLogs")
    else
      set_status("Error:GetLogs")
    end
  end

  def heroku_get_remote_configuration
    head = __method__
    set_status("GetConfiguration")
    heroku_reset_api
    log "#{head}: Getting configuration variables for Remote #{endpoint.at_type} #{heroku_app_name}."
    result = HerokuHeadless.heroku.get_config_vars(heroku_app_name)
    if result && result.data[:body]
      vars_set = result.data[:body].keys
      log "#{head}: Remote Configuration Variables #{vars_set.join(", ")} have been set for Remote #{endpoint.at_type} #{heroku_app_name}."
      set_status("Success:Configure")
    else
      set_status("Error:Configure")
    end
  rescue Exception => boom
    log "#{head}: Cannot configure Remote #{endpoint.at_type} #{heroku_app_name} - #{boom}"
    set_status("Error:Configure")
  end
  
end