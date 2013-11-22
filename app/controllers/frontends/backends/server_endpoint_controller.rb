class Frontends::Backends::ServerEndpointController < ApplicationController

  def index
    get_context
    if @backend
      @server_endpoints = @backend.server_endpoints
    else
      raise NotFoundError
    end
  end

  def show
    get_context!
  end

  def num(name)
    match = /.*([0-9]+)/.match(name)
    if match
      n = match[1].to_i
    else
      0
    end
  end

  def new
    get_context
    if @backend
      @deployment_types = ["Heroku", "Unix", "Heroku-Swift", "Heroku-SSH", "Unix-Swift", "Unix-SSH"]
      names = ServerEndpoint.where(:name => /#{@backend.name}-server/).map {|x| x.name}
      last_name = names.sort {|x,y| num(x) <=> num(y) }.last
      n = num(last_name) + 1
      name = "#{@backend.name}-server#{n}"
      @server_endpoint = ServerEndpoint.new(
          :backend => @backend,
          :name => name,
          :remote_configuration_literal => "{}"
      )
    else
      raise NotFoundError
    end
  end

  def edit
    get_context
    if @backend
      if ["Heroku", "Heroku-Swift", "Heroku-SSH"].include? @server_endpoint.deployment_type
        @deployment_types = ["Heroku", "Heroku-Swift", "Heroku-SSH"]
      elsif ["Unix", "Unix-Swift", "Unix-SSH"].include? @server_endpoint.deployment_type
        @deployment_types = ["Unix", "Unix-Swift", "Unix-SSH"]
      else
        @deployment_types = ["Heroku", "Unix", "Heroku-Swift", "Heroku-SSH", "Unix-Swift", "Unix-SSH"]
      end
    else
      raise NotFoundError
    end
  end

  def create
    get_context
    if @backend
      @server_endpoint = ServerEndpoint.new(params[:server_endpoint])
      @server_endpoint.backend = @backend
      if @server_endpoint.remote_configuration_literal.blank?
        @server_endpoint.remote_configuration_literal = "{}"
      end

      if @server_endpoint.valid?
        @server_endpoint.save
        flash[:notice] = "Endpoint #{@server_endpoint.name} created."
        redirect_to frontend_backend_server_endpoints_path
      else
        @deployment_types = ["Heroku", "Unix", "Heroku-Swift", "Heroku-SSH", "Unix-Swift", "Unix-SSH"]
        render :new
      end
    else
      raise NotFoundError
    end
  end

  def update
    get_context
    if params[:server_endpoint][:remote_configuration_literal].blank?
      params[:server_endpoint][:remote_configuration_literal] = "{}"
    end
    if @server_endpoint.update_attributes(params[:server_endpoint])
      flash[:notice] = "Endpoint #{@server_endpoint.name} created."
      redirect_to frontend_backend_server_endpoints_path
    else
      if ["Heroku", "Heroku-Swift", "Heroku-SSH"].include? @server_endpoint.deployment_type
        @deployment_types = ["Heroku", "Heroku-Swift", "Heroku-SSH"]
      elsif ["Unix", "Unix-Swift", "Unix-SSH"].include @server_endpoint.deployement_type
        @deployment_types = ["Unix", "Unix-Swift", "Unix-SSH"]
      else
        @deployment_types = ["Heroku", "Unix", "Heroku-Swift", "Heroku-SSH", "Unix-Swift", "Unix-SSH"]
      end
      render :new
    end
  end

  def destroy
    get_context!
    flash[:notice] = "Server Endpoint #{@server_endpoint.name} deleted."
    @server_endpoint.destroy
    redirect_to frontend_backend_server_endpoints_path(@frontend, @backend)
  end

  def partial_status
    get_context!
    if @server_endpoint_job
      index = params[:log_end].to_i
      @logs = @server_endpoint_job.logger.segment(index, 100)
    else
      render :nothing => true
    end
  end

  def clear_log
    get_context!
    if @server_endpoint_job
      @server_endpoint_job.logger.clear
    end
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def create_app
    get_context!
    job = DeployServerEndpointJob.get_job(@server_endpoint, "create_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Server Endpoint #{@server_endpoint.name}  will be created if doesn't already exist."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def destroy_app
    get_context!
    job = DeployServerEndpointJob.get_job(@server_endpoint, "destroy_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Server Endpoint #{@server_endpoint.name}  will be destroyed."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def deploy_app
    get_context!
    job = DeployServerEndpointJob.get_job(@server_endpoint, "deploy_to_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "A job has been queued to deploy Server Endpoint #{@server_endpoint.name}. Check log."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def remote_status
    get_context!
    job = DeployServerEndpointJob.get_job(@server_endpoint, "status_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Remote Status for Server Endpoint #{@server_endpoint.name} is being updated."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def get_logs
    get_context!
    job = DeployServerEndpointJobspec.new(@server_endpoint.deploy_server_endpoint_job.id, @server_endpoint.name, "logs_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Remote Logs for Server Endpoint #{@server_endpoint.name} will be updated."
    redirect_to remote_log_frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def remote_log
    get_context!
  end

  def truncate_remote_logs
    get_context!
    job = DeployServerEndpointJob.get_job(@server_endpoint, "truncate_logs_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Remote Logs for Server Endpoint #{@server_endpoint.name} will be truncated."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def start_app
    get_context!
    job = DeployServerEndpointJob.get_job(@server_endpoint, "start_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Server Endpoint #{@server_endpoint.name} will be started."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def restart_app
    get_context!
    job = DeployServerEndpointJob.get_job(@server_endpoint, "restart_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Server Endpoint #{@server_endpoint.name} will be restarted."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def configure_app
    get_context!
    job = DeployServerEndpointJob.get_job(@server_endpoint, "configure_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Server Endpoint #{@server_endpoint.name}  will be configured."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def stop_app
    get_context!
    job = DeployServerEndpointJob.get_job(@server_endpoint, "stop_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Server Endpoint #{@server_endpoint.name}  will be stopped."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  protected

  def get_context
    @frontend = Frontend.find(params[:frontend_id])
    @installation = @frontend.installation if @frontend
    @backend = @frontend.backends.find(params[:backend_id]) if @frontend
    if @backend
      @server_endpoint = @backend.server_endpoints.find(params[:id])
      if @server_endpoint
        @server_endpoint_job = DeployServerEndpointJob.where(:endpoint_id => @server_endpoint.id).first
      end
    end
  end

  def get_context!
    get_context
    raise NotFoundError if @server_endpoint.nil?
  end
end