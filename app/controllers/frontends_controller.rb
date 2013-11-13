class FrontendsController < ApplicationController

  def index
    @frontends = Frontend.all
  end

  def new
    @installation = Installation.find(params[:installation_id]) if params[:installation_id]
    @frontend = Frontend.new(:installlation => @installation)
    @frontend_types = ["nginx"]
    @installations = Installation.all
  end

  def edit
    @frontend = Frontend.find params[:id]
    @frontend_types = [@frontend.deployment_type]
    @installations = [@frontend.installation]
  end

  def show
    @frontend = Frontend.find(params[:id])
    if @frontend
    end
  end

  def create
    @frontend = Frontend.new(params[:frontend])
    if @frontend.valid?
      @frontend.save
      flash[:notice] = "Frontend created"
      if @frontend.installation.frontends.count > 1
        redirect_to installation_path(@frontend.installation)
      else
        redirect_to frontend_path(@frontend)
      end
    else
      flash[:error] = "Could not create frontend"
      @frontend_types = ["ec2", "unix"]
      @installations = Installation.all
      render :new
    end
  end

  def update
    @frontend = Frontend.find params[:id]
    if @frontend.update_attributes(params[:frontend])
      flash[:notice] = "Frontend updated"
      redirect_to frontend_path(@frontend)
    else
      flash[:error] = "Could not update frontend"
      @frontend_types = [@frontend.deployment_type]
      @installations = [@frontend.installation]
      render :edit
    end
  end

  def destroy
    @frontend = Frontend.find(params[:id])
    if @frontend
      if @frontend.backends.count == 0
        jobspec = DeployFrontendJob.get_job(@frontend, "destroy_remote_frontend")
        Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
        flash[:notice] = "A job has been submitted to destroy the frontend"
      else
        flash[:error] = "Frontend still has backends"
      end
      redirect_to frontend_path(@frontend)
    else
      flash[:error] = "Cannot find Frontend"
      redirect_to installations_path
    end
  end

  def create_remote
    @frontend = Frontend.find(params[:id])
    if @frontend
      if @frontend.remote_key && @frontend.admin_user
        jobspec = DeployFrontendJob.get_job(@frontend, "create_remote_frontend")
        Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
        flash[:notice] = "A job has been submitted to create the frontend"
      else
        flash[:error] = "Frontend needs key and admin_user"
      end
    else
      flash[:error] = "Cannot find Frontend"
    end
    redirect_to frontend_path(@frontend)
  end

  def configure_remote
    @frontend = Frontend.find(params[:id])
    if @frontend
      if @frontend.remote_key && @frontend.admin_user
        jobspec = DeployFrontendJob.get_job(@frontend, "configure_remote_frontend")
        Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
        flash[:notice] = "A job has been submitted to configure the frontend"
      else
        flash[:error] = "Frontend needs key and admin_user"
      end
    else
      flash[:error] = "Cannot find Frontend"
    end
    redirect_to frontend_path(@frontend)
  end

  def deconfigure_remote
    @frontend = Frontend.find(params[:id])
    if @frontend
      if @frontend.remote_key && @frontend.admin_user
        jobspec = DeployFrontendJob.get_job(@frontend, "deconfigure_remote_frontend")
        Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
        flash[:notice] = "A job has been submitted to configure the frontend"
      else
        flash[:error] = "Frontend needs key and admin_user"
      end
    else
      flash[:error] = "Cannot find Frontend"
    end
    redirect_to frontend_path(@frontend)
  end

  def start_remote
    @frontend = Frontend.find(params[:id])
    if @frontend
      if @frontend.remote_key && @frontend.admin_user
        jobspec = DeployFrontendJob.get_job(@frontend, "start_remote_frontend")
        Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
        flash[:notice] = "A job has been submitted to start the frontend"
      else
        flash[:error] = "Frontend needs key and admin_user"
      end
    else
      flash[:error] = "Cannot find Frontend"
    end
    redirect_to frontend_path(@frontend)
  end

  def stop_remote
    @frontend = Frontend.find(params[:id])
    if @frontend
      if @frontend.remote_key && @frontend.admin_user
        jobspec = DeployFrontendJob.get_job(@frontend, "stop_remote_frontend")
        Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
        flash[:notice] = "A job has been submitted to start the frontend"
      else
        flash[:error] = "Frontend needs key and admin_user"
      end
    else
      flash[:error] = "Cannot find Frontend"
    end
    redirect_to frontend_path(@frontend)
  end

  def deploy_to_remote
    @frontend = Frontend.find(params[:id])
    if @frontend
      if @frontend.remote_key && @frontend.admin_user
        jobspec = DeployFrontendJob.get_job(@frontend, "deploy_to_remote_frontend")
        Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
        flash[:notice] = "Frontend is being deployed on the remote end."
      else
        flash[:error] = "Frontend needs key and admin_user"
      end
    end
    redirect_to frontend_path(@frontend)
  end

  def destroy_remote
    @frontend = Frontend.find(params[:id])
    if @frontend
      jobspec = DeployFrontendJob.get_job(@frontend, "destroy_remote_frontend")
      Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
      flash[:notice] = "A job has been submitted to destroy the frontend and all backends"
      redirect_to installation_path(@frontend.installation)
    else
      flash[:error] = "Cannot find Frontend"
      redirect_to installations_path
    end
  end

  def destroy_all_backends
    get_context!
    @frontend.backends.each do |backend|
      job = DeployBackendJob.get_job(backend, "destroy_remote_backend")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "Frontend #{@frontend.name}'s '#{@frontend.backends.count} backends are being destroyed."
  end

  def restart_all_endpoints
    get_context!
    @frontend.endpoints.each do |endpoint|
      job = DeployEndpointJob.get_job(endpoint, "restart_remote_endpoint")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
    end
    flash[:notice] = "Frontend #{@frontend.name}'s '#{@frontend.endpoints.count} endpoints are being restarted."
  end

  def partial_status
    index = params[:log_end].to_i
    if @frontend_job
      @logs = @frontend_job.logger.segment(index, 100)
      @status = @frontend_job.remote_status
    end
  end

  def clear_log
    get_context!
    @frontend_job.logger.clear if @frotend_job
  end

  protected

  def get_context
    @frontend = Frontend.find(params[:id])
    @frontend_job = DeployFrontendJob.where(:frontend_id => @frontend) if @frontend
  end

  def get_context!
    get_context
    railse NotFoundError if @frontend.nil?
  end
end