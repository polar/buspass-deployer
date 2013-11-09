class FrontendsController < ApplicationController

  def index
    @frontends = Frontend.all
  end

  def new
    @installation = Installation.find(params[:installation_id]) if params[:installation_id]
    @frontend = Frontend.new(:installlation => @installation)
    @frontend_types = ["ec2"]
    @installations = Installation.all
  end

  def edit
    @frontend = Frontend.find params[:id]
    @frontend_types = ["ec2"]
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
      @frontend_types = ["ec2"]
      @installations = Installation.all
      render :new
    end
  end

  def update
    @frontend = Frontend.find params[:id]
    if @frontend
      args = params[:frontend].slice("host", "hostip")
      args[:name] = args["host"] if args["host"]
      @frontend.update_attributes(args)
      if @frontend.deploy_frontend_job.nil?
        @frontend.create_deploy_frontend_job()
      end
      @frontend.save
      flash[:notice] = "Frontend updated"
      redirect_to frontends_path
    else
      flash[:error] = "Could not update frontend"
      @frontend_types = ["ec2"]
      @installations = [@frontend.installation]
      render :edit
    end
  end

  def destroy_notused
    @frontend = Frontend.find(params[:id])
    if @frontend
      if @frontend.backends.empty?
        flash[:notice] = "Frontend #{@frontend.host} - #{@frontend.base_hostname} deleted."
        @frontend.destroy
      else
        flash[:error] = "You need to destroy all backends first"
      end
    else
      flash[:error] = "Frontend not found."
    end
    redirect_to frontends_path
  end

  def destroy
    @frontend = Frontend.find(params[:id])
    if @frontend
      if @frontend.deploy_frontend_job.nil?
        @frontend.create_deploy_frontend_job
      end
      job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "destroy_frontend", nil, nil)
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      flash[:notice] = "A job has been submitted to destroy the frontend"
      redirect_to status_installation_path(@frontend.installation)
    else
      flash[:error] = "Cannot find Frontend"
      redirect_to :back
    end
  end

  def upload_key
    @frontend = Frontend.find(params[:id])
    if @frontend
      @frontend_key = @frontend.frontend_key
      if @frontend_key
        if !@frontend_key.exists?
          @frontend_key.destroy
          @frontend_key = FrontendKey.new
        else
          flash[:notice] = "Frontend key is #{@frontend_key.name}"
        end
      else
        @frontend_key = FrontendKey.new
      end
    else
      flash[:error] = "Frontend not found."
      redirect_to frontends_path
    end
  end

  def store_key
    @frontend = Frontend.find(params[:id])
    if @frontend
      if @frontend.frontend_key
        @frontend.frontend_key.destroy
      end
      @frontend_key = FrontendKey.new(params[:frontend_key])
      @frontend_key.frontend = @frontend
      @frontend_key.save
      @frontend.save
      if (@frontend_key.exists?)
        @frontend_key.encrypt_key_content(@frontend_key.ssh_key.file.read)
        @frontend_key.save
      end
      redirect_to frontend_path(@frontend)
    else
      flash[:error] = "Frontend not found."
      redirect_to frontends_path
    end
  end

  def configure
    @frontend = Frontend.find(params[:id])
    if @frontend
      if @frontend.configured
        flash[:error] = "Already configured."
      else
        case @frontend.deployment_type
          when "ec2"
            if @frontend.remote_key && @frontend.remote_user
              jobspec = DeployFrontendJob.get_job(@frontend, "configure_remote_frontend")
              Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
              flash[:notice] = "Frontend is being configured on the remote end."
            else
              flash[:error] = "Frontend needs key and admin_user"
            end
          else
            flash[:error] = "Unknown Frontend Type #{@frontend.deployment_type}"
        end
      end
      redirect_to frontend_backends_path(@frontend)
    else
      redirect_to :back
    end
  end

  def full_configure
    @frontend = Frontend.find(params[:id])
    if @frontend
      flash[:notice] = "Frontend #{@frontend.name} full (re)configuration has started."
      job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "configure_remote_frontend", nil, nil)
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "configure_remote_frontend_backends", nil, nil)
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      redirect_to frontend_backends_path(@frontend)
    else
      flash[:error] = "Frontend not found."
      redirect_to :back
    end
  end

  def start
    @frontend = Frontend.find(params[:id])
    if @frontend
      if request.method == "POST"
        if ! @frontend.configured
          flash[:error] = "Not configured."
        else
          jobspec = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "start_remote_frontend", nil, nil)
          Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
          flash[:notice] = "Frontend is being started on the remote end."
        end
      end
    end
    redirect_to :back
  end

  def stop
    @frontend = Frontend.find(params[:id])
    if @frontend
      if request.method == "POST"
        if ! @frontend.configured
          flash[:error] = "Not configured."
        else
          jobspec = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "stop_remote_frontend", nil, nil)
          Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
          flash[:notice] = "Frontend is being stopped on the remote end."
        end
      end
    end
    redirect_to :back
  end

  def install
    @frontend = Frontend.find(params[:id])
    if @frontend
      if request.method == "POST"
        if @frontend.git_commit
          flash[:error] = "Frontend is already installed."
        else
          case @frontend.deployment_type
            when "ec2"
              if @frontend.remote_key && @frontend.admin_user
                jobspec = DeployFrontendJob.get_job(@frontend, "create_remote_frontend")
                Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
                flash[:notice] = "Frontend is being installed on the remote end."
              else
                flash[:error] = "Frontend needs key and admin_user"
              end
            else
              flash[:error] = "Unknown Frontend Type #{@frontend.deployment_type}"
          end
        end
      end
    end
    redirect_to frontend_backends_path(@frontend)
  end

  def upgrade
    @frontend = Frontend.find(params[:id])
    if @frontend
      if request.method == "POST"
        case @frontend.deployment_type
          when "ec2"
            if @frontend.remote_key && @frontend.admin_user
              jobspec = DeployFrontendJob.get_job(@frontend, "deploy_to_remote_frontend")
              Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
              flash[:notice] = "Frontend is being installed on the remote end."
            else
              flash[:error] = "Frontend needs key and admin_user"
            end
          else
            flash[:error] = "Unknown Frontend Type #{@frontend.deployment_type}"
        end
      end
    end
    redirect_to frontend_backends_path(@frontend)
  end

  def deconfigure
    @frontend = Frontend.find(params[:id])
    if @frontend
      if ! @frontend.configured
        flash[:error] = "Not configured."
      else
        jobspec = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "deconfigure_remote_frontend", nil, nil)
        Delayed::Job.enqueue(jobspec, :queue => "deploy-web")
        flash[:notice] = "Frontend is being deconfigured on the remote end."
      end
    end
    redirect_to :back
  end

  def destroy_backends
    @frontend = Frontend.find(params[:id])
    if @frontend
      # This may need to be a job.
      @frontend.backends.each {|b| b.destroy }
      flash[:notice] = "Backends are destroyed"
    else
      flash[:error] = "Frontend not found."
    end
    redirect_to frontends_path
  end

  def create_all_endpoint_apps
    get_context!
    if @frontend.deploy_frontend_job.nil?
      @frontend.create_deploy_frontend_job
    end
    job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "create_all_endpoint_apps", nil, nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    redirect_to :back
  end

  def configure_all_endpoint_apps
    get_context!
    if @frontend.deploy_frontend_job.nil?
      @frontend.create_deploy_frontend_job
    end
    job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "configure_all_endpoint_apps", nil, nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    redirect_to :back
  end

  def start_all_endpoint_apps
    get_context!
    if @frontend.deploy_frontend_job.nil?
      @frontend.create_deploy_frontend_job
    end
    job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "start_all_endpoint_apps", nil, nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    redirect_to :back
  end

  def restart_all_endpoint_apps
    get_context!
    if @frontend.deploy_frontend_job.nil?
      @frontend.create_deploy_frontend_job
    end
    job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "restart_all_endpoint_apps", nil, nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    redirect_to :back
  end

  def stop_all_endpoint_apps
    get_context!
    if @frontend.deploy_frontend_job.nil?
      @frontend.create_deploy_frontend_job
    end
    job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "stop_all_endpoint_apps", nil, nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    redirect_to :back
  end

  def deploy_all_endpoint_apps
    get_context!
    if @frontend.deploy_frontend_job.nil?
      @frontend.create_deploy_frontend_job
    end
    job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "deploy_all_endpoint_apps", nil, nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    redirect_to :back
  end

  def destroy_all_endpoint_apps
    get_context!
    if @frontend.deploy_frontend_job.nil?
      @frontend.create_deploy_frontend_job
    end
    job = DeployFrontendJobspec.new(@frontend.deploy_frontend_job.id, @frontend.host, "destroy_all_endpoint_apps", nil, nil)
    Delayed::Job.enqueue(job, :queue => "deploy-web")
    redirect_to :back
  end

  def clear_log
    @frontend = Frontend.find(params[:id])
    @frontend.frontend_log.clear
    @frontend.frontend_log.save
    redirect_to :back
  end

  protected

  def get_context
    @frontend = Frontend.find(params[:id])
  end

  def get_context!
    get_context
    railse NotFoundError if @frontend.nil?
  end
end