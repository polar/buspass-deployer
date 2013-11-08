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

  def new
    get_context
    if @backend
      @server_endpoint = ServerEndpoint.new_instance_for_backend(@backend)
    else
      raise NotFoundError
    end
  end

  def create
    get_context
    if @backend
      @server_endpoint = ServerEndpoint.new(params[:server_endpoint])
      @server_endpoint.backend = @backend
      if @server_endpoint.name.blank?
        @server_endpoint.name = @server_enpoint.remote_name
      end
      if @server_endpoint.remote_name.blank?
        @server_endpoint.name = @server_endpoint.name
      end
      if @server_endpoint.valid?
        @server_endpoint.save
        @server_endpoint.create_server_endpoint_log
        @server_endpoint.create_deploy_server_endpoint_job
        flash[:notice] = "Endpoint #{@server_endpoint.name} created."
        redirect_to frontend_backend_server_endpoints_path
      else
        render :new
      end
    else
      raise NotFoundError
    end
  end

  def destroy
    get_context!
    flash[:notice] = "Server Endpoint #{@server_endpoint.name} destroyed."
    @server_endpoint.destroy
    redirect_to frontend_backend_server_endpoints_path(@frontend, @backend)
  end

  def partial_status
    get_context!
    @server_endpoint = ServerEndpoint.find(params[:id])
    if @server_endpoint
      index = params[:log_end].to_i
      @logs = @server_endpoint.server_endpoint_log.segment(index, 100)
    else
      render :nothing => true
    end
  end

  def clear_log
    get_context!
    @server_endpoint.server_endpoint_log.clear
    @server_endpoint.server_endpoint_log.save
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def create_app
    get_context!
    if @server_endpoint.deploy_server_endpoint_job.nil?
      @server_endpoint.create_deploy_server_endpoint_job
    end
    @server_endpoint.deploy_server_endpoint_job.reset_api
    job = DeployServerEndpointJobspec.new(@server_endpoint.deploy_server_endpoint_job.id, @server_endpoint.name, "create_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be created if doesn't already exist."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def destroy_app
    get_context!
    if @server_endpoint.deploy_server_endpoint_job.nil?
      @server_endpoint.create_deploy_server_endpoint_job
    end
    job = DeployServerEndpointJobspec.new(@server_endpoint.deploy_server_endpoint_job.id, @server_endpoint.name, "destroy_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be destroyed."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def deploy_app
    get_context!
    if @server_endpoint.deploy_server_endpoint_job.nil?
      @server_endpoint.create_deploy_server_endpoint_job
    end
    job = DeployServerEndpointJobspec.new(@server_endpoint.deploy_server_endpoint_job.id, @server_endpoint.name, "job_create_and_deploy_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "A job has been queued to deploy Server Endpoint. Check log."
    redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
  end

  def remote_status
    get_context!
    job = DeployServerEndpointJobspec.new(@server_endpoint.deploy_server_endpoint_job.id, @server_endpoint.name, "remote_endpoint_status")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Remote Status is being updated."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
    end
  end

  def get_logs
    get_context!
    if request.method == "POST"
      job = DeployServerEndpointJobspec.new(@server_endpoint.deploy_server_endpoint_job.id, @server_endpoint.name, "logs_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      flash[:notice] = "Remote Logs will be updated."
      redirect_to remote_log_frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
    else
      redirect_to remote_log_frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
    end
  end

  def remote_log
    get_context!
  end

  def truncate_remote_logs
    get_context!
    if request.method == "POST"
      job = DeployServerEndpointJobspec.new(@server_endpoint.deploy_server_endpoint_job.id, @server_endpoint.name, "truncate_logs_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      flash[:notice] = "Remote Logs will be truncated."
      redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
    else
      redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
    end
  end



  def start_app
    get_context!
    job = DeployServerEndpointJobspec.new(@server_endpoint.deploy_server_endpoint_job.id, @server_endpoint.name, "start_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be started."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
    end
  end

  def restart_app
    get_context!
    job = DeployServerEndpointJobspec.new(@server_endpoint.deploy_server_endpoint_job.id, @server_endpoint.name, "restart_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be started."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
    end
  end

  def configure_app
    get_context!
    job = DeployServerEndpointJobspec.new(@server_endpoint.deploy_server_endpoint_job.id, @server_endpoint.name, "configure_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be started."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
    end
  end

  def stop_app
    get_context!
    job = DeployServerEndpointJobspec.new(@server_endpoint.deploy_server_endpoint_job.id, @server_endpoint.name, "stop_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be stopped."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_server_endpoint_path(@frontend, @backend, @server_endpoint)
    end
  end

  protected

  def get_context
    @frontend = Frontend.find(params[:frontend_id])
    @backend = @frontend.backends.find(params[:backend_id]) if @frontend
    @server_endpoint = @backend.server_endpoints.find(params[:id]) if @backend
  end

  def get_context!
    get_context
    raise NotFoundError if @server_endpoint.nil?
  end
end