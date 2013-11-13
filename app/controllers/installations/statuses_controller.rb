class Installations::StatusesController < ApplicationController

  def index
    get_context
  end

  def get_context
    @installation = Installation.find(params[:installation_id])
    @state = DeployState.find(:params[:id])
  end
end