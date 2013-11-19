class Frontends::BackendsController < ApplicationController

  def index
    get_context
    if @frontend.nil?
      flash[:error] = "Frontend not found. Stale URL?"
      if request.env["HTTP_REFERER"]
        redirect_to :back
      else
        raise NotFoundError
      end
    end
  end

  def show
    get_context!
  end

  def new
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      @backend = @frontend.backends.build(
          :name      => "#{@frontend.name}-b#{Backend.count}",
          :hostnames => [@frontend.remote_host, "*.#{@frontend.remote_host}"],
      )
      @backend.server_proxies.build(:proxy_type=> "SSH")
      @backend.server_proxies.build(:proxy_type=> "Swift")
    end
  end

  def edit
    get_context!
  end

  def update
    get_context!
    params[:backend][:hostnames] = params[:backend][:hostnames].split(" ")
    params[:backend][:locations] = params[:backend][:locations].split(" ")
    if @backend.update_attributes(params[:backend])
      flash[:notice] = "Backend updated, but not configured."
      redirect_to frontend_backend_path(@frontend, @backend)
    else
      flash[:error] = "Cannot create backend."
      render :edit
    end
  end

  def create
    get_context
    @backend = Backend.new()
    @backend.frontend = @frontend
    @backend.server_proxies.build(:proxy_type=> "SSH")
    @backend.server_proxies.build(:proxy_type=> "Swift")

    params[:backend][:hostnames] = params[:backend][:hostnames].split(" ")
    params[:backend][:locations] = params[:backend][:locations].split(" ")
    @backend.attributes = params[:backend]
    if @backend.valid?
      @backend.save
      flash[:notice] = "Backend #{@backend.name} is created"
      redirect_to frontend_path(@backend.frontend)
    else
      flash[:error] = "Backend #{@backend.name} could not be created"
      render :new
    end
  end

  def destroy
    get_context!
    job = DeployBackendJob.get_job(@backend, "destroy_remote_backend")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Backend #{@backend.name} and all its endpoints will be destroyed."
    redirect_to frontend_backends_path(@frontend)
  end

  def delete
    get_context!
    @backend.destroy
    flash[:notice] = "Backend #{@backend.name} and all its endpoints have been deleted."
    redirect_to frontend_backends_path(@frontend)
  end

  def configure
    get_context!
    job = DeployBackendJob.get_job(@backend, "configure_remote_backend")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Backend #{@backend.name} will be configured."
    redirect_to :back
  end

  def deconfigure
    get_context!
    job = DeployBackendJob.get_job(@backend, "deconfigure_remote_backend")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Backend #{@backend.name} will deconfigured."
    redirect_to :back
  end

  def start
    get_context!
    job = DeployBackendJob.get_job(@backend, "start_remote_backend")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Backend #{@backend.name} will be started."
    redirect_to :back
  end

  def restart
    get_context!
    job = DeployBackendJob.get_job(@backend, "restart_remote_backend")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Backend #{@backend.name} will be restarted."
    redirect_to :back
  end

  def status
    get_context!
    job = DeployBackendJob.get_job(@backend, "status_remote_backend")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Backend #{@backend.name} status."
    redirect_to :back
  end

  def stop
    get_context!
    job = DeployBackendJob.get_job(@backend, "stop_remote_backend")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Backend #{@backend.name} will be stopped."
    redirect_to :back
  end

  def start_all
    get_context
    @frontend.backends.each do |backend|
      job = DeployFrontendJob.get_job(backend, "start_remote_backend")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All Backends of #{@frontend.name} will be started."
    redirect_to :back
  end

  def stop_all
    get_context
    @frontend.backends.each do |backend|
      job = DeployFrontendJob.get_job(backend, "stop_remote_backend")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All Backends of #{@frontend.name} will be stopped."
    redirect_to :back
  end

  def restart_all
    get_context
    @frontend.backends.each do |backend|
      job = DeployFrontendJob.get_job(backend, "restart_remote_backend")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All Backends of #{@frontend.name} will be restarted."
    redirect_to :back
  end

  def status_all
    get_context
    @frontend.backends.each do |backend|
      job = DeployFrontendJob.get_job(backend, "status_remote_backend")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All Backends of #{@frontend.name} will retrieve status."
    redirect_to :back
  end

  def create_all_server_endpoint_apps
    get_context!
    @backend.server_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "create_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All server endpoints for Backend #{@backend.name} will be created."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def configure_all_server_endpoint_apps
    @backend.server_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "configure_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All server endpoints for Backend #{@backend.name} will be configured."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def deploy_all_server_endpoint_apps
    get_context!
    @backend.server_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "deploy_to_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All server endpoints for Backend #{@backend.name} will be deployed."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def destroy_all_server_endpoint_apps
    get_context!
    @backend.server_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "destroy_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All server endpoints for Backend #{@backend.name} will be destroyed."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def start_all_server_endpoint_apps
    get_context!
    @backend.server_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "start_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All server endpoints for Backend #{@backend.name} will be started."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def restart_all_server_endpoint_apps
    get_context!
    @backend.server_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "restart_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All server endpoints for Backend #{@backend.name} will be restarted."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def stop_all_server_endpoint_apps
    get_context!
    @backend.server_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "stop_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All server endpoints for Backend #{@backend.name} will be stopped."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def status_all_server_endpoint_apps
    get_context!
    @backend.server_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "status_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All server endpoints for Backend #{@backend.name} will get status updates."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def create_all_worker_endpoint_apps
    get_context!
    @backend.worker_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "create_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All worker endpoints for Backend #{@backend.name} will be created."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def configure_all_worker_endpoint_apps
    get_context!
    @backend.worker_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "configure_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All worker endpoints for Backend #{@backend.name} will be configured."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def deploy_all_worker_endpoint_apps
    get_context!
    @backend.worker_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "deploy_to_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All worker endpoints for Backend #{@backend.name} will be deployed."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def destroy_all_worker_endpoint_apps
    get_context!
    @backend.worker_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "destroy_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All worker endpoints for Backend #{@backend.name} will be destroyed."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def start_all_worker_endpoint_apps
    get_context!
    @backend.worker_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "start_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All worker endpoints for Backend #{@backend.name} will be started."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def restart_all_worker_endpoint_apps
    get_context!
    @backend.worker_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "restart_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All worker endpoints for Backend #{@backend.name} will be restarted."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def stop_all_worker_endpoint_apps
    get_context!
    @backend.worker_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "stop_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All worker endpoints for Backend #{@backend.name} will be stopped."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def status_all_worker_endpoint_apps
    get_context!
    @backend.worker_endpoints.each do |endpoint|
      job = DeployServerEndpointJob.get_job(endpoint, "status_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "All worker endpoints for Backend #{@backend.name} will get status updates."
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  #
  # These work for both collection and member
  def partial_status
    get_context!
    if @backend_job
      index = params[:log_end].to_i
      @logs = @backend_job.logger.segment(index, 100)
    else
      if @backend.nil? && @frontend_job
        @logs = @frontend_job.logger.segment(index, 100)
      end
    end
  end

  def clear_log
    get_context
    if @backend_job
      @backend_job.logger.clear
    else
      if @backend.nil? && @frontend_job
        @frontend_job.logger.clear
      end
    end
    redirect_to :back
  end

  protected

  def get_context
    @frontend = Frontend.find(params[:frontend_id])
    @backend = @frontend.backends.find(params[:id]) if @frontend
    @frontend_job = DeployFrontendJob.where(:frontend_id => @frontend.id).first if @frontend
    @backend_job = DeployBackendJob.where(:backend_id => @backend.id).first if @backend
  end

  def get_context!
    get_context
    raise NotFoundError if @backend.nil?
  end
end