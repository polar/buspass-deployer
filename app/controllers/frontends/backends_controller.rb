class Frontends::BackendsController < ApplicationController

  def index
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      if @frontend.frontend_key.nil? || ! @frontend.frontend_key.exists?
        flash[:error] = "You need to upload a PEM key for this frontend to manage it."
      end
    else
      flash[:error] = "Frontend not found. Stale URL?"
      if request.env["HTTP_REFERER"]
        redirect_to :back
      else
        raise NotFoundError
      end
    end
  end

  def show
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      @backend = @frontend.backends.find(params[:id])
      if @backend

      else
        flash[:error] = "Backend not found."
        redirect_to :back
      end
    else
      flash[:error] = "Frontend not found."
      redirect_to :back
    end
  end

  def frontend_partial_status
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      index = params[:log_end].to_i
      @logs = @frontend.frontend_log.segment(index, 100)
      @hostip = @frontend.hostip
      @remote_configured = "#{@frontend.configured}"
    end
  end

  def edit_software
    @frontend = Frontend.find(params[:frontend_id])
  end


  def update_software
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      attrs = params[:frontend].slice("endpoint_git_repository", "endpoint_git_name", "endpoint_git_refspec")
      @frontend.update_attributes(attrs)
    end
    redirect_to frontend_backends_path(@frontend)
  end

  def status_all
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      if request.method == "POST"
        jobspec = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "status_remote_frontend", nil, nil)
        Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
        redirect_to status_all_frontend_backends_path(@frontend)
      end
    else
      redirect_to frontend_backends_path
    end
  end

  def partial_status_all
    @frontend = Frontend.find(params[:frontend_id])
    index = params[:log_end].to_i
    @logs = @frontend.frontend_log.segment(index, 100)
    if @frontend.nil?
      render :nothing => true
    end
  end

  def new
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      ports = (@frontend.backends.map {|x| x.cluster_port.to_i }.max || 2999) + 1

      @backend = Backend.new(
          :frontend => @frontend,
          :frontend_address => "0.0.0.0",
          :cluster_address => "127.0.0.1",
          :cluster_port => (@frontend.backends.map {|x| x.cluster_port.to_i }.max || 2999) + 1,
          :address => "0.0.0.0",
          :port => (@frontend.backends.map {|x| x.port.to_i }.max || 3999) + 1,
      )
      @master_slugs = Master.order(:slug).map { |m| m.slug }
      @disabled_master_slugs = Backend.where(:frontend_id => @frontend.id).all.map {|be| be.master_slug}
    end
  end

  def new_base
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      ports = (@frontend.backends.map {|x| x.cluster_port.to_i }.max || 2999) + 1

      if @frontend.backends.where(:hostname => @frontend.host).first.nil?
        hostname = @frontend.host
      end
      if @frontend.backends.where(:server_name => "*.#{@frontend.host}").first.nil?
        server_name = "*.#{@frontend.host}"
      end
      @backend = Backend.new(
          :frontend => @frontend,
          :frontend_address => "0.0.0.0",
          :hostname => hostname,
          :server_name => server_name,
          :cluster_address => "127.0.0.1",
          :cluster_port => (@frontend.backends.map {|x| x.cluster_port.to_i }.max || 2999) + 1,
          :address => "0.0.0.0",
          :port => (@frontend.backends.map {|x| x.port.to_i }.max || 3999) + 1,
      )
    end
  end

  def create
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      params[:backend][:frontend] = @frontend
      @backend = Backend.new(params[:backend])
      if @backend.valid?
        @backend.save
        flash[:notice] = "Backend created, but not configured."
        @frontend.log "Created Backend #{@backend.name}."
        redirect_to frontend_backends_path(@frontend)
      else
        flash[:error] = "Cannot create backend."
        if params["submit"] = "Create Base Backend"
          render :new_base
        else
          @master_slugs = Master.order(:slug).map { |m| m.slug }
          render :new
        end
      end
    else
      flash[:error] = "Frontend does not exist."
    end
  end

  def destroy
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      backend = @frontend.backends.find(params[:id])
      if backend.configured
        flash[:error] = "Backend must be deconfigured first."
      else
        flash[:notice] = "Backend #{backend.name} destroyed."
        @frontend.log "Backend #{backend.name} destroyed."
        backend.destroy
      end
      redirect_to frontend_backends_path(@frontend)
    else
      flash[:error] = "Frontend not found."
      redirect_to :back
    end
  end

  def configure
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      if @frontend.configured
        backend = @frontend.backends.find(params[:id])
        if backend
          flash[:notice] = "Backend #{backend.name} is configured."
          job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "configure_remote_backend", backend.id, backend.name)
          Delayed::Job.enqueue(job, :queue => "deploy-web")
          #job.perform
        else
          flash[:error] = "Backend not found"
        end
      else
        flash[:error] = "Frontend needs to be configured first."
      end
    else
      flash[:error] = "Frontend not found."
    end
    redirect_to :back
  end

  def deconfigure
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      backend = @frontend.backends.find(params[:id])
      if backend
        flash[:notice] = "Backend #{backend.name} is deconfigured."
        if @frontend.deploy_frontend_job.nil?
          @frontend.create_deploy_frontend_job
          @frontend.save
        end

        job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "deconfigure_remote_backend", backend.id, backend.name)
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        #job.perform
      else
        flash[:error] = "Backend not found"
      end
      redirect_to frontend_backends_path(@frontend)
    else
      flash[:error] = "Frontend not found."
      redirect_to :back
    end
  end

  def start
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      backend = @frontend.backends.find(params[:id])
      if backend
        flash[:notice] = "Backend #{backend.name} started."
        job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "start_remote_backend", backend.id, backend.name)
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        #job.perform
      else
        flash[:error] = "Backend not found"
      end
    else
      flash[:error] = "Frontend not found."
    end
    redirect_to :back
  end

  def restart
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      backend = @frontend.backends.find(params[:id])
      if backend
        flash[:notice] = "Backend #{backend.name} started."
        job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "restart_remote_backend", backend.id, backend.name)
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        #job.perform
      else
        flash[:error] = "Backend not found"
      end
    else
      flash[:error] = "Frontend not found."
    end
    redirect_to :back
  end

  def status
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      @backend = @frontend.backends.find(params[:id])
      if @backend
        if request.method == "POST"
          job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "status_remote_frontend", nil, nil)
          Delayed::Job.enqueue(job, :queue => "deploy-web")
          #job.perform
        end
      else
        flash[:error] = "Backend not found"
        redirect_to :back
      end
    else
      flash[:error] = "Frontend not found."
      redirect_to :back
    end
  end

  def stop
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      backend = @frontend.backends.find(params[:id])
      if backend
        flash[:notice] = "Backend #{backend.name} stopped."
        job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "stop_remote_backend", backend.id, backend.name)
        Delayed::Job.enqueue(job, :queue => "deploy-web")
        #job.perform
      else
        flash[:error] = "Backend not found"
      end
    else
      flash[:error] = "Frontend not found."
    end
    redirect_to :back
  end

  def start_all
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      flash[:notice] = "Frontend #{@frontend.name} backends will be started."
      job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "start_remote_backends", nil, nil)
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      #job.perform
    end
    redirect_to :back
  end

  def stop_all
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      flash[:notice] = "Frontend #{@frontend.name} backends will be stopped."
      job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "stop_remote_backends", nil, nil)
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      #job.perform
    end
    redirect_to :back
  end

  def restart_all
    @frontend = Frontend.find(params[:frontend_id])
    if @frontend
      flash[:notice] = "Frontend #{@frontend.name} backends will be restarted."
      job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "restart_remote_backends", nil, nil)
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      #job.perform
    end
    redirect_to :back
  end

  def create_all_swift_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "create_swift_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to create all swift endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def configure_all_swift_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "configure_swift_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to configure all swift endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def deploy_all_swift_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "deploy_swift_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to deploy to all swift endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def destroy_all_swift_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "destroy_swift_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to destroy to all swift endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def start_all_swift_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "start_swift_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to start all swift endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def restart_all_swift_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "restart_swift_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to restart all swift endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def stop_all_swift_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "stop_swift_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to stop all swift endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def status_all_swift_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "status_swift_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to get status of swift endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def create_all_server_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "create_server_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to create all server endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def configure_all_server_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "configure_server_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to configure all server endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def deploy_all_server_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "deploy_server_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to deploy to all server endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def destroy_all_server_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "destroy_server_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to destroy to all server endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def start_all_server_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "start_server_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to start all server endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def restart_all_server_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "restart_server_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to restart all server endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def stop_all_server_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "stop_server_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to stop all server endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def status_all_server_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "status_server_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to get status of server endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def create_all_worker_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "create_worker_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to create all worker endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def configure_all_worker_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "configure_worker_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to configure all worker endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def deploy_all_worker_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "deploy_worker_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to deploy to all worker endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def destroy_all_worker_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "destroy_worker_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to destroy to all worker endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def start_all_worker_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "start_worker_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to start all worker endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def restart_all_worker_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "restart_worker_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to start all worker endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def stop_all_worker_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "stop_worker_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to stop all worker endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def status_all_worker_endpoint_apps
    get_context!
    if @backend.deploy_backend_job.nil?
      @backend.create_deploy_backend_job
    end
    job = DeployBackendJobspec.new(@backend.deploy_backend_job.id, @backend.name, "status_worker_endpoint_apps", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to get status of worker endpoints"
    redirect_to frontend_backend_path(@frontend, @backend)
  end

  def partial_status
    get_context!
      index = params[:log_end].to_i
      @logs = @backend.backend_log.segment(index, 100)
  end

  def clear_log
    get_context
    if @backend
      @backend.backend_log.clear
      @backend.backend_log.save
    else
      @frontend.frontend_log.clear
      @frontend.frontend_log.save
    end
    redirect_to :back
  end

  protected

  def get_context
    @frontend = Frontend.find(params[:frontend_id])
    @backend = @frontend.backends.find(params[:id]) if @frontend
  end

  def get_context!
    get_context
    raise NotFoundError if @backend.nil?
  end
end