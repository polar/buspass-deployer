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
      @deployment_types = ["Heroku", "Unix"]
      names = ServerEndpoint.where(:name => /#{@backend.name}-worker/).map {|x| x.name}
      last_name = names.sort {|x,y| num(x) <=> num(y) }.last
      n = num(last_name) + 1
      name = "#{@backend.name}-worker#{n}"
      @worker_endpoint = WorkerEndpoint.new(
          :backend => @backend,
          :name => name,
      )
    else
      raise NotFoundError
    end
  end

  def create
    get_context
    if @backend
      @worker_endpoint = WorkerEndpoint.new(params[:worker_endpoint])
      @worker_endpoint.backend = @backend

      if @worker_endpoint.valid?
        @worker_endpoint.save
        flash[:notice] = "Endpoint #{@worker_endpoint.name} created."
        redirect_to frontend_backend_worker_endpoints_path
      else
        @deployment_types = ["Heroku", "Unix"]
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
    if @worker_endpoint_job
      index = params[:log_end].to_i
      @logs = @worker_endpoint_job.endpoint_log.segment(index, 100)
    else
      render :nothing => true
    end
  end

  def clear_log
    get_context!
    if @worker_endpoint_job
      @worker_endpoint_job.endpoint_log.clear
      @worker_endpoint_job.endpoint_log.save
    end
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def create_app
    get_context!
    job = DeployWorkerEndpointJob.get_job(@worker_endpoint, "create_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Worker Endpoint #{@worker_endpoint.name}  will be created if doesn't already exist."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def destroy_app
    get_context!
    job = DeployWorkerEndpointJob.get_job(@worker_endpoint, "destroy_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Worker Endpoint #{@worker_endpoint.name}  will be destroyed."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def deploy_app
    get_context!
    job = DeployWorkerEndpointJob.get_job(@worker_endpoint, "deploy_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "A job has been queued to deploy Worker Endpoint #{@worker_endpoint.name}. Check log."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def remote_status
    get_context!
    job = DeployWorkerEndpointJob.get_job(@worker_endpoint, "status_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Remote Status for Worker Endpoint #{@worker_endpoint.name} is being updated."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def get_logs
    get_context!
    job = DeployWorkerEndpointJob.get_job(@worker_endpoint, "logs_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Remote Logs for Worker Endpoint #{@worker_endpoint.name} will be updated."
    redirect_to remote_log_frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def remote_log
    get_context!
  end

  def truncate_remote_logs
    get_context!
    job = DeployWorkerEndpointJob.get_job(@worker_endpoint, "truncate_logs_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Remote Logs for Worker Endpoint #{@worker_endpoint.name} will be truncated."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def start_app
    get_context!
    job = DeployWorkerEndpointJob.get_job(@worker_endpoint, "start_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Worker Endpoint #{@worker_endpoint.name} will be started."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def restart_app
    get_context!
    job = DeployWorkerEndpointJob.get_job(@worker_endpoint, "restart_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Worker Endpoint #{@worker_endpoint.name} will be restarted."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def configure_app
    get_context!
    job = DeployWorkerEndpointJob.get_job(@worker_endpoint, "configure_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Worker Endpoint #{@worker_endpoint.name}  will be configured."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  def stop_app
    get_context!
    job = DeployWorkerEndpointJob.get_job(@worker_endpoint, "stop_remote_endpoint")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Worker Endpoint #{@worker_endpoint.name}  will be stopped."
    redirect_to frontend_backend_worker_endpoint_path(@frontend, @backend, @worker_endpoint)
  end

  protected

  def get_context
    @frontend = Frontend.find(params[:frontend_id])
    @installation = @frontend.installation if @frontend
    @backend = @frontend.backends.find(params[:backend_id]) if @frontend
    if @backend
      @worker_endpoint = @backend.worker_endpoints.find(params[:id])
      if @worker_endpoint
        @worker_endpoint_job = DeployWorkerEndpointJob.where(:endpoint_id => @worker_endpoint.id).first
      end
    end
  end

  def get_context!
    get_context
    raise NotFoundError if @worker_endpoint.nil?
  end
end