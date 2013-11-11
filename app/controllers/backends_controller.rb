class BackendsController < ApplicationController

  def index
    @backends = Backend.all
  end

  def new
    get_context
    @backend = Backend.new
    @backend.frontend = @frontend
    @deployment_types = ["ssh", "swift", "server"]
    if @backend.frontend
      count = @backend.frontend.backends.count
      @backend.name = "#{@backend.frontend.name}-backend-#{count}"
    end
  end

  def create
    get_context
    params[:backend][:hostnames] = params[:backend][:hostnames].split(" ")
    params[:backend][:proxy_addresses] = params[:backend][:proxy_addresses].split(" ")
    params[:backend][:backend_addresses] = params[:backend][:backend_addresses].split(" ")
    @backend.frontend = @frontend
    @backend = Backend.new(params[:backend])
    if @backend.valid?
      @backend.save
      flash[:notice] = "Backend #{@backend.name} is created"
      redirect_to frontend_path(@backend.frontend)
    else
      flash[:error] = "Backend #{@backend.name} could not be created"
      @deployment_types = ["ssh", "swift", "server"]
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