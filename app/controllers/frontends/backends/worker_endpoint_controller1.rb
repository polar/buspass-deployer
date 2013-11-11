class Frontends::Backends::WorkerEndpointController < ApplicationController

  def index
    get_context
    if @backend
      @worker_endpoints = @backend.worker_endpoints
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
      @worker_endpoint = WorkerEndpoint.new_instance_for_backend(@backend)
    else
      raise NotFoundError
    end
  end

  def create
    get_context
    if @backend
      @worker_endpoint = WorkerEndpoint.new(params[:worker_endpoint])
      @worker_endpoint.backend = @backend
      if @worker_endpoint.name.blank?
        @worker_endpoint.name = @worker_enpoint.remote_name
      end
      if @worker_endpoint.remote_name.blank?
        @worker_endpoint.name = @worker_endpoint.name
      end
      if @worker_endpoint.valid?
        @worker_endpoint.save
        @worker_endpoint.create_worker_endpoint_log
        @worker_endpoint.create_deploy_worker_endpoint_job
        flash[:notice] = "Worker Endpoint #{@worker_endpoint.name} created."
        redirect_to frontend_backend_worker_endpoints_path
      else
        render :new
      end
    else
      raise NotFoundError
    end
  end

  def destroy
    get_context!
    flash[:notice] = "Worker Endpoint #{@worker_endpoint.name} destroyed."
    @worker_endpoint.destroy
    redirect_to frontend_backend_worker_endpoints_path(@frontend, @backend)
  end

  def partial_status
    get_context!
    @worker_endpoint = WorkerEndpoint.find(params[:id])
    if @worker_endpoint
      index = params[:log_end].to_i
      @logs = @worker_endpoint.worker_endpoint_log.segment(index, 100)
    else
      render :nothing => true
    end
  end

  def clear_log
    get_context!
    @worker_endpoint.worker_endpoint_log.clear
    @worker_endpoint.worker_endpoint_log.save
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def create_app
    get_context!
    if @worker_endpoint.deploy_worker_endpoint_job.nil?
      @worker_endpoint.create_deploy_worker_endpoint_job
      @worker_endpoint.save
    end
    @worker_endpoint.deploy_worker_endpoint_job.reset_api
    job = DeployWorkerEndpointJobspec.new(@worker_endpoint.deploy_worker_endpoint_job.id, @worker_endpoint.name, "create_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Worker Endpoint App will be created if not already exists."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def destroy_app
    get_context!
    if @worker_endpoint.deploy_worker_endpoint_job.nil?
      @worker_endpoint.create_deploy_worker_endpoint_job
      @worker_endpoint.save
    end
    job = DeployWorkerEndpointJobspec.new(@worker_endpoint.deploy_worker_endpoint_job.id, @worker_endpoint.name, "destroy_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be destroyed."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def deploy_app
    get_context!
    if @worker_endpoint.deploy_worker_endpoint_job.nil?
      @worker_endpoint.create_deploy_worker_endpoint_job
      @worker_endpoint.save
    end
    job = DeployWorkerEndpointJobspec.new(@worker_endpoint.deploy_worker_endpoint_job.id, @worker_endpoint.name, "job_create_and_deploy_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "A job has been queued to Deploy Worker Endpoint. Check log."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def remote_status
    get_context!
    job = DeployWorkerEndpointJobspec.new(@worker_endpoint.deploy_worker_endpoint_job.id, @worker_endpoint.name, "remote_endpoint_status")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Remote Status is being updated."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
    end
  end

  def get_logs
    get_context!
    if request.method == "POST"
      job = DeployWorkerEndpointJobspec.new(@worker_endpoint.deploy_worker_endpoint_job.id, @worker_endpoint.name, "logs_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      flash[:notice] = "Remote Logs will be updated."
      redirect_to remote_log_frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
    else
      redirect_to remote_log_frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
    end
  end

  def remote_log
    get_context!
  end

  def start_app
    get_context!
    job = DeployWorkerEndpointJobspec.new(@worker_endpoint.deploy_worker_endpoint_job.id, @worker_endpoint.name, "start_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be started."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
    end
  end

  def restart_app
    get_context!
    job = DeployWorkerEndpointJobspec.new(@worker_endpoint.deploy_worker_endpoint_job.id, @worker_endpoint.name, "restart_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be started."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
    end
  end

  def configure_app
    get_context!
    job = DeployWorkerEndpointJobspec.new(@worker_endpoint.deploy_worker_endpoint_job.id, @worker_endpoint.name, "configure_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be started."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
    end
  end

  def stop_app
    get_context!
    job = DeployWorkerEndpointJobspec.new(@worker_endpoint.deploy_worker_endpoint_job.id, @worker_endpoint.name, "stop_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Endpoint App will be stopped."
    if request.method == "POST"
      redirect_to :back
    else
      redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
    end
  end

  def truncate_remote_logs
    get_context!
    if request.method == "POST"
      job = DeployWorkerEndpointJobspec.new(@worker_endpoint.deploy_worker_endpoint_job.id, @worker_endpoint.name, "truncate_logs_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      flash[:notice] = "Remote Logs will be truncated."
      redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
    else
      redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
    end
  end

  protected

  def get_context
    @frontend = Frontend.find(params[:frontend_id])
    @backend = @frontend.backends.find(params[:backend_id]) if @frontend
    @worker_endpoint = @backend.worker_endpoints.find(params[:id]) if @backend
  end

  def get_context!
    get_context
    raise NotFoundError if @worker_endpoint.nil?
  end
end