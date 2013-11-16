class InstallationsController < ApplicationController

  def index
    @installations = Installation.all
  end

  def show
    @installation = Installation.find(params[:id])
    raise NotFoundError if  @installation.nil?
  end

  def edit
    @installation = Installation.find params[:id]
    @ssh_key_names = RemoteKey.all.map {|x| x.name}
    @deploy_heroku_api_key_names = DeployHerokuApiKey.all.map {|x| x.name}
  end

  def new
    @installation = Installation.new
    @ssh_key_names = RemoteKey.all.map {|x| x.name}
    @deploy_heroku_api_key_names = DeployHerokuApiKey.all.map {|x| x.name}
  end

  def create
    @installation = Installation.new(params[:installation])
    if @installation.valid?
      flash[:notice] = "New installation #{@installation.name} has been created."
      @installation.save
      redirect_to installation_path(@installation)
    else
      flash[:error] = "Could not create new installation."
      @ssh_key_names = RemoteKey.all.map {|x| x.name}
      @deploy_heroku_api_key_names = DeployHerokuApiKey.all.map {|x| x.name}
      render :new
    end
  end

  def update
    @installation = Installation.find params[:id]
    if @installation.update_attributes(params[:installation])
      flash[:notice] = "installation #{@installation.name} has been updated."
      @installation.save
      redirect_to installation_path(@installation)
    else
      flash[:error] = "Could not update new installation."
      @ssh_key_names = RemoteKey.all.map {|x| x.name}
      @deploy_heroku_api_key_names = DeployHerokuApiKey.all.map {|x| x.name}
      render :edit
    end
  end

  def destroy
    get_context!
    if @installation
      @installation.destroy
      flash[:notice] = "Installation #{@installation.name} has been destroyed."
    else
      flash[:error] = "Installation not found. Stale URL?"
    end
    redirect_to installations_path
  end

  def edit_frontend_git
    get_context!
  end

  def update_frontend_git
    get_context!
    args = params[:installation].slice(:frontend_git_repository, :frontend_git_refspec, :frontend_git_name)
    @installation.update_attributes(args)
    redirect_to installation_path(@installation)
  end

  def edit_server_endpoint_git
    get_context!
  end

  def update_server_endpoint_git
    get_context!
    args = params[:installation].slice(:server_endpoint_git_repository, :server_endpoint_git_refspec, :server_endpoint_git_name)
    @installation.update_attributes(args)
    @installation.save
    redirect_to installation_path(@installation)
  end

  def edit_worker_endpoint_git
    get_context!
  end

  def update_worker_endpoint_git
    get_context!
    args = params[:installation].slice(:worker_endpoint_git_repository, :worker_endpoint_git_refspec, :worker_endpoint_git_name)
    @installation.update_attributes(args)
    redirect_to installation_path(@installation)
  end

  def create_all
    get_context!
    if job_check_failed
      redirect_to deploy_status_installation_path(@installation)
      return
    end
    job = DeployInstallationJob.get_job(@installation, "create_installation")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to create the installation"
    redirect_to deploy_status_installation_path(@installation)
  end

  def configure_all
    get_context!
    if job_check_failed
      redirect_to deploy_status_installation_path(@installation)
      return
    end
    job = DeployInstallationJob.get_job(@installation, "configure_installation")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to configure the installation"
    redirect_to deploy_status_installation_path(@installation)
  end

  def start_all
    get_context!
    if job_check_failed
      redirect_to deploy_status_installation_path(@installation)
      return
    end
    job = DeployInstallationJob.get_job(@installation, "start_installation")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to start the installation"
    redirect_to deploy_status_installation_path(@installation)
  end

  def deploy_all
    get_context!
    if job_check_failed
      redirect_to deploy_status_installation_path(@installation)
      return
    end
    job = DeployInstallationJob.get_job(@installation, "deploy_to_installation")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to deploy the installation"
    redirect_to deploy_status_installation_path(@installation)
  end

  def stop_all
    get_context!
    if job_check_failed
      redirect_to deploy_status_installation_path(@installation)
      return
    end
    job = DeployInstallationJob.get_job(@installation, "stop_installation")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to stop the installation"
    redirect_to deploy_status_installation_path(@installation)
  end

  def destroy_all
    get_context!
    if job_check_failed
      redirect_to deploy_status_installation_path(@installation)
      return
    end
    job = DeployInstallationJob.get_job(@installation, "destroy_installation")
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to destroy the installation"
    redirect_to deploy_status_installation_path(@installation)
  end

  def destroy_all_jobs
    get_context!
    if job_check_failed
      redirect_to deploy_status_installation_path(@installation)
      return
    end
    count = 0
    DeployJob.where(:installation_id => @installation.id).each {|x| x.destroy; count += 1}
    flash[:notice] = "#{count} Installation #{@installation.name} DeployJobs have been destroyed."
    redirect_to deploy_status_installation_path(@installation)
  end

  def clear_log
    get_context!
    if @installation_job
      @installation_job.logger.clear
    end
    redirect_to :back
  end

  def status
    get_context!
  end

  def deploy_status
    get_context!
  end

  def partial_deploy_status
    get_context!
  end

  def partial_status
    get_context!
    index = params[:log_end].to_i
    if @installation_job
       @logs = @installation_job.logger.segment(index, 100)
    end
  end


  def ping_remote_status
    get_context!
    if job_check_failed
      redirect_to deploy_status_installation_path(@installation)
      return
    end
    DeployJob.where(:installation_id => @installation.id).each {|x| x.destroy}
    @installation.frontends.each do |frontend|
      job = DeployFrontendJob.get_job(frontend, "status_remote_frontend")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      frontend.backends.each do |backend|
        job = DeployBackendJob.get_job(backend, "status_remote_backend")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
      end
      frontend.endpoints.each do |endpoint|
        job = DeployEndpointJob.get_job(endpoint, "status_remote_endpoint")
        Delayed::Job.enqueue(job, :queue => "deploy-web")
      end
    end
    redirect_to deploy_status_installation_path(@installation)
  end

  protected

  def get_context
    @installation = Installation.find(params[:id])
    @isntallation_job = DeployInstallationJob.where(:installation_id => @installation) if @installation
  end

  def get_context!
    get_context
    raise NotFoundError if @installation.nil?
  end

  def job_check_failed
    count = DeployJob.where(:installation_id => @installation.id).reduce(0) {|t,v| t + v.delayed_jobs.count}
    if count > 0
      flash[:error] = "Jobs are still queued. You must wait until all jobs are finished."
      return true
    end
    return false
  end
end