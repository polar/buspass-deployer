class DeployHerokuApiKeysController < ApplicationController
  def index
    @deploy_heroku_api_keys = DeployHerokuApiKey.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @deploy_heroku_api_keys }
    end
  end

  # GET /deploy_heroku_api_keys/1
  # GET /deploy_heroku_api_keys/1.json
  def show
    get_context!

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @deploy_heroku_api_key }
    end
  end

  # GET /deploy_heroku_api_keys/new
  # GET /deploy_heroku_api_keys/new.json
  def new
    @deploy_heroku_api_key = DeployHerokuApiKey.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @deploy_heroku_api_key }
    end
  end

  # POST /deploy_heroku_api_keys
  # POST /deploy_heroku_api_keys.json
  def create
    @deploy_heroku_api_key = DeployHerokuApiKey.new(params[:deploy_heroku_api_key])

    @deploy_heroku_api_key.encrypt_key_content(params[:value], :key => params[:key])

    respond_to do |format|
      if @deploy_heroku_api_key.save
        format.html { redirect_to @deploy_heroku_api_key, notice: 'Heroku key was successfully created.' }
        format.json { render json: @deploy_heroku_api_key, status: :created, location: @deploy_heroku_api_key }
      else
        format.html { render action: "new" }
        format.json { render json: @deploy_heroku_api_key.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    get_context!
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @deploy_heroku_api_key }
    end
  end

  def update
    get_context!

    respond_to do |format|
      if @deploy_heroku_api_key.update_attributes(params[:deploy_heroku_api_key_path])
        format.html { redirect_to @deploy_heroku_api_key, notice: 'Heroku key was successfully created.' }
        format.json { render json: @deploy_heroku_api_key, status: :created, location: @deploy_heroku_api_key }
      else
        format.html { render action: "new" }
        format.json { render json: @deploy_heroku_api_key.errors, status: :unprocessable_entity }
      end
    end

  end

  # DELETE /deploy_heroku_api_keys/1
  # DELETE /deploy_heroku_api_keys/1.json
  def destroy
    get_context!
    @deploy_heroku_api_key.destroy

    respond_to do |format|
      format.html { redirect_to deploy_heroku_api_keys_path }
      format.json { head :no_content }
    end
  end

  protected

  def get_context
    @deploy_heroku_api_key = DeployHerokuApiKey.find_by_name(params[:name]) if params[:name]
    @deploy_heroku_api_key = DeployHerokuApiKey.find(params[:id]) if @deploy_heroku_api_key.nil?
  end

  def get_context!
    get_context
    raise NotFoundError if @deploy_heroku_api_key.nil?
  end
end
