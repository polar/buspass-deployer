class BackendsController < ApplicationController

  def index
    @backends = Backend.all
  end

  def new
    @backend = Backend.new
    @master_slugs = Master.order(:slug).map { |m| m.slug }
    @frontends = Frontend.all
    @backend.frontend = Frontend.find(params[:frontend_id]) if params[:frontend_id]
  end

  def destroy
    backend = Backend.find(params[:id])
    if backend
      if backend.deploy_backend_job.nil?
        backend.create_deploy_backend_job
      end
      job = DeployBackendJobspec.new(backend.deploy_backend_job.id, backend.name, "destroy_backend")
      Delayed::Job.enqueue(job, :queue => "deploy-web")
      flash[:notice] = "Backend #{backend.name} and its endpoints will be destroyed."
      redirect_to frontend_path(backend.frontend)
    else
      flash[:error] = "Backend not found."
      redirect_to :back
    end
  end
end