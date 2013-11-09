class BackendsController < ApplicationController

  def index
    @backends = Backend.all
  end

  def new
    @backend = Backend.new
    @frontends = Frontend.all
    @backend.frontend = Frontend.find(params[:frontend_id]) if params[:frontend_id]
    @deployment_types = ["ssh", "swift"]
    if @backend.frontend
      count = @backend.frontend.backends.count
      @backend.name = "#{@backend.frontend.name}-backend-#{count}"
    end
  end

  def create
    params[:backend][:hostnames] = params[:backend][:hostnames].split(" ")
    params[:backend][:proxy_addresses] = params[:backend][:proxy_addresses].split(" ")
    params[:backend][:backend_addresses] = params[:backend][:backend_addresses].split(" ")
    @backend = Backend.new(params[:backend])
    if @backend.valid?
      @backend.save
      flash[:notice] = "Backend #{@backend.name} is created"
      redirect_to frontend_path(@backend.frontend)
    else
      flash[:error] = "Backend #{@backend.name} could not be created"
      @frontends = Frontend.all
      @deployment_types = ["ssh", "swift"]
      render :new
    end
  end

  def destroy
    backend = Backend.find(params[:id])
    if backend
      job = DeployBackendJob.get_job(backend, "destroy_remote_backend")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      flash[:notice] = "Backend #{backend.name} and its endpoints will be destroyed."
      redirect_to frontend_path(backend.frontend)
    else
      flash[:error] = "Backend not found."
      redirect_to :back
    end
  end
end