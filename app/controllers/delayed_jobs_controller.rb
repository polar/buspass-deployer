class DelayedJobsController < ApplicationController

  def index
    @delayed_jobs = Delayed::Job.where(:queue => "deploy-web").order(:run_at).all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @delayed_jobs }
    end
  end

  def destroy
    begin
      @delayed_job = Delayed::Job.find(params[:id])
      @delayed_job.destroy
      flash[:notice] = "Job destroyed."
    rescue Exception => boom
      flash[:error] = "Job not destroyed. Probably expired."
    end

    respond_to do |format|
      format.html { redirect_to delayed_jobs_path }
      format.json { head :no_content }
    end
  end

  def destroy_all
    Delayed::Job.where(:queue => "deploy-web").each {|x| x.destroy}
    respond_to do |format|
      format.html { redirect_to delayed_jobs_path }
      format.json { head :no_content }
    end
  end
end
