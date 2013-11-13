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
    @keynames = RemoteKey.all.map {|x| x.name}
  end

  def new
    @installation = Installation.new
    @keynames = RemoteKey.all.map {|x| x.name}
  end

  def create
    @installation = Installation.new(params[:installation])
    if @installation.valid?
      flash[:notice] = "New installation #{@installation.name} has been created."
      @installation.save
      redirect_to installation_path(@installation)
    else
      flash[:error] = "Could not create new installation."
      render :new
    end
  end

  def update
    @installation = Installation.find params[:id]
    if @installation.update_attributes(params[:installation])
      flash[:notice] = "New installation #{@installation.name} has been created."
      @installation.save
      redirect_to installation_path(@installation)
    else
      flash[:error] = "Could not update new installation."
      @keynames = RemoteKey.all.map {|x| x.name}
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
    @installation.frontends.each do |frontend|
      job = DeployFrontendJob.get_job(frontend, "create_installation")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "Job has been launched to create the installation"
    if @installation.frontends.count > 1
      redirect_to installation_path(@installation)
    else
      redirect_to frontend_backends_path(@installation.frontends.first)
    end
  end

  def configure_all
    get_context!
    @installation.frontends.each do |frontend|
      job = DeployFrontendJob.get_job(frontend, "configure_installation")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "Job has been launched to configure the installation"
    if @installation.frontends.count > 1
      redirect_to installation_path(@installation)
    else
      redirect_to frontend_backends_path(@installation.frontends.first)
    end
  end

  def start_all
    get_context!
    @installation.frontends.each do |frontend|
      job = DeployFrontendJob.get_job(frontend, "start_installation")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "Job has been launched to install the installation frontends"
    if @installation.frontends.count > 1
      redirect_to installation_path(@installation)
    else
      redirect_to frontend_backends_path(@installation.frontends.first)
    end
  end

  def deploy_all
    get_context!
    @installation.frontends.each do |frontend|
      job = DeployFrontendJob.get_job(frontend, "deploy_to_installation")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "Job has been launched to deploy the installation"
    if @installation.frontends.count > 1
      redirect_to installation_path(@installation)
    else
      redirect_to frontend_backends_path(@installation.frontends.first)
    end
  end

  def stop_all
    get_context!
    @installation.frontends.each do |frontend|
      job = DeployFrontendJob.get_job(frontend, "stop_installation")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "Job has been launched to install the installation frontends"
    if @installation.frontends.count > 1
      redirect_to installation_path(@installation)
    else
      redirect_to frontend_backends_path(@installation.frontends.first)
    end
  end

  def destroy_all
    get_context!
    @installation.frontends.each do |frontend|
      job = DeployFrontendJob.get_job(frontend, "destroy_installation")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "Job has been launched to destroy the installation"
    if @installation.frontends.count > 1
      redirect_to installation_path(@installation)
    else
      redirect_to frontend_backends_path(@installation.frontends.first)
    end
  end

  def clear_log
    get_context!
    if @installation_job
      @installation_job.loggerl.clear
    end
    redirect_to :back
  end

  def status
    get_context!
  end

  def deploy_status
    get_context!
  end

  def partial_status
    get_context!
    index = params[:log_end].to_i
    if @installation_job
       @logs = @installation_job.logger.segment(index, 100)
    end
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
end