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

  def edit_swift_endpoint_git
    get_context!
  end

  def update_server_endpoint_git
    get_context!
    args = params[:installation].slice(:server_endpoint_git_repository, :server_endpoint_git_refspec, :server_endpoint_git_name)
    @installation.update_attributes(args)
    @installation.save
    redirect_to installation_path(@installation)
  end

  def update_swift_endpoint_git
    get_context!
    args = params[:installation].slice(:swift_endpoint_git_repository, :swift_endpoint_git_refspec, :swift_endpoint_git_name)
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

  def install_frontends
    get_context!
    @installation.frontends.each do |frontend|
      job = DeployFrontendJob.get_job(frontend, "deploy_remote_frontend")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "Job has been launched to install the installation frontends"
    if @installation.frontends.count > 1
      redirect_to installation_path(@installation)
    else
      redirect_to frontend_backends_path(@installation.frontends.first)
    end
  end

  def start_frontends
    get_context!
    if @installation.deploy_installation_job.nil?
      @installation.create_deploy_installation_job
    end
    job = DeployInstallationJobspec.new(@installation.deploy_installation_job.id, "start_frontends", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to start the installation frontends"
    redirect_to installation_path(@installation)
  end

  def upgrade
    get_context!
    if @installation.deploy_installation_job.nil?
      @installation.create_deploy_installation_job
    end
   # @installation.deploy_installation_job.null_all_statuses
    job = DeployInstallationJobspec.new(@installation.deploy_installation_job.id, "upgrade_installation", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to upgrade the installation"
    redirect_to status_installation_path(@installation)
  end

  def start
    get_context!
    if @installation.deploy_installation_job.nil?
      @installation.create_deploy_installation_job
    end
    @installation.deploy_installation_job.null_all_statuses
    job = DeployInstallationJobspec.new(@installation.deploy_installation_job.id, "start_installation", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to start the installation"
    redirect_to status_installation_path(@installation)
  end

  def stop
    get_context!
    if @installation.deploy_installation_job.nil?
      @installation.create_deploy_installation_job
    end
    job = DeployInstallationJobspec.new(@installation.deploy_installation_job.id, "stop_installation", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to stop the installation"
    redirect_to status_installation_path(@installation)
  end

  def clear_log
    get_context!
    @installation.installation_log.clear
    @installation.installation_log.save
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
    @logs = @installation.installation_log.segment(index, 100)
  end

  def partial_deploy_status
    get_context!
    index = params[:log_end].to_i
    @logs = @installation.installation_log.segment(index, 100)
  end

  def ping_remote_status
    get_context!
    if @installation.deploy_installation_job.nil?
      @installation.create_deploy_installation_job
    end
    @installation.deploy_installation_job.null_all_statuses
    @installation.deploy_installation_job.null_remote_statuses
    job = DeployInstallationJobspec.new(@installation.deploy_installation_job.id, "remote_status_installation", nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    flash[:notice] = "Job has been launched to update the remote status."
    redirect_to status_installation_path(@installation)
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

  protected

  def get_context
    @installation = Installation.find(params[:id])
  end

  def get_context!
    get_context
    raise NotFoundError if @installation.nil?
  end
end