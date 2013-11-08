class Frontends::Backends::SwiftEndpointController < ApplicationController


  def index
    get_context
    if @backend
      @swift_endpoints = @backend.swift_endpoints
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
      @swift_endpoint = SwiftEndpoint.new_instance_for_backend(@backend)
    else
      raise NotFoundError
    end
  end

  def create
    get_context
    if @backend
      @swift_endpoint = SwiftEndpoint.new(params[:swift_endpoint])
      @swift_endpoint.backend = @backend
      if @swift_endpoint.name.blank?
        @swift_endpoint.name = @swift_enpoint.remote_name
      end
      if @swift_endpoint.remote_name.blank?
        @swift_endpoint.name = @swift_endpoint.name
      end
      if @swift_endpoint.valid?
        @swift_endpoint.save
        @swift_endpoint.create_swift_endpoint_log
        @swift_endpoint.create_deploy_swift_endpoint_job
        flash[:notice] = "Endpoint #{@swift_endpoint.name} created."
        redirect_to frontend_backend_swift_endpoints_path
      else
        render :new
      end
    else
      raise NotFoundError
    end
  end

  def destroy
    get_context!
    flash[:notice] = "Swift Endpoint #{@swift_endpoint.name} destroyed."
    @swift_endpoint.destroy
    redirect_to frontend_backend_swift_endpoints_path(@frontend, @backend)
  end

  def partial_status
    get_context!
    @swift_endpoint = SwiftEndpoint.find(params[:id])
    if @swift_endpoint
      index = params[:log_end].to_i
      @logs = @swift_endpoint.swift_endpoint_log.segment(index, 100)
    else
      render :nothing => true
    end
  end

  def clear_log
    get_context!
    @swift_endpoint.swift_endpoint_log.clear
    @swift_endpoint.swift_endpoint_log.save
    redirect_to frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
  end

  def create_app
    get_context!
    if @swift_endpoint.deploy_swift_endpoint_job.nil?
      @swift_endpoint.create_deploy_swift_endpoint_job
    end
    @swift_endpoint.deploy_swift_endpoint_job.reset_api
    job = DeploySwiftEndpointJobspec.new(@swift_endpoint.deploy_swift_endpoint_job.id, @swift_endpoint.name, "create_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be created if doesn't already exist."
    redirect_to frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
  end

  def destroy_app
    get_context!
    if @swift_endpoint.deploy_swift_endpoint_job.nil?
      @swift_endpoint.create_deploy_swift_endpoint_job
    end
    job = DeploySwiftEndpointJobspec.new(@swift_endpoint.deploy_swift_endpoint_job.id, @swift_endpoint.name, "destroy_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be destroyed."
    redirect_to frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
  end

  def deploy_app
    get_context!
    if @swift_endpoint.deploy_swift_endpoint_job.nil?
      @swift_endpoint.create_deploy_swift_endpoint_job
    end
    job = DeploySwiftEndpointJobspec.new(@swift_endpoint.deploy_swift_endpoint_job.id, @swift_endpoint.name, "job_create_and_deploy_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "A job has been queued to deploy Swift Endpoint. Check log."
    redirect_to frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
  end

  def remote_status
    get_context!
    job = DeploySwiftEndpointJobspec.new(@swift_endpoint.deploy_swift_endpoint_job.id, @swift_endpoint.name, "remote_endpoint_status")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Remote Status is being updated."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
    end
  end

  def get_logs
    get_context!
    if request.method == "POST"
      job = DeploySwiftEndpointJobspec.new(@swift_endpoint.deploy_swift_endpoint_job.id, @swift_endpoint.name, "logs_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      flash[:notice] = "Remote Logs will be updated."
      redirect_to remote_log_frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
    else
      redirect_to remote_log_frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
    end
  end

  def remote_log
    get_context!
  end

  def truncate_remote_logs
    get_context!
    if request.method == "POST"
      job = DeploySwiftEndpointJobspec.new(@swift_endpoint.deploy_swift_endpoint_job.id, @swift_endpoint.name, "truncate_logs_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      flash[:notice] = "Remote Logs will be truncated."
      redirect_to frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
    else
      redirect_to frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
    end
  end



  def start_app
    get_context!
    job = DeploySwiftEndpointJobspec.new(@swift_endpoint.deploy_swift_endpoint_job.id, @swift_endpoint.name, "start_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be started."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
    end
  end

  def restart_app
    get_context!
    job = DeploySwiftEndpointJobspec.new(@swift_endpoint.deploy_swift_endpoint_job.id, @swift_endpoint.name, "restart_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be started."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
    end
  end

  def configure_app
    get_context!
    job = DeploySwiftEndpointJobspec.new(@swift_endpoint.deploy_swift_endpoint_job.id, @swift_endpoint.name, "configure_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be started."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
    end
  end

  def stop_app
    get_context!
    job = DeploySwiftEndpointJobspec.new(@swift_endpoint.deploy_swift_endpoint_job.id, @swift_endpoint.name, "stop_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be stopped."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_swift_endpoint_path(@frontend, @backend, @swift_endpoint)
    end
  end

  protected

  def get_context
    @frontend = Frontend.find(params[:frontend_id])
    @backend = @frontend.backends.find(params[:backend_id]) if @frontend
    @swift_endpoint = @backend.swift_endpoints.find(params[:id]) if @backend
  end

  def get_context!
    get_context
    raise NotFoundError if @swift_endpoint.nil?
  end
end