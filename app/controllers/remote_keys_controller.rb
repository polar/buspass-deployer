class RemoteKeysController < ApplicationController
  # GET /remote_keys
  # GET /remote_keys.json
  def index
    @remote_keys = RemoteKey.order(:updated_at).all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @remote_keys }
    end
  end

  # GET /remote_keys/1
  # GET /remote_keys/1.json
  def show
    get_context!

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @remote_key }
    end
  end

  # GET /remote_keys/new
  # GET /remote_keys/new.json
  def new
    @remote_key = RemoteKey.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @remote_key }
    end
  end

  # POST /remote_keys
  # POST /remote_keys.json
  def create
    @remote_key = RemoteKey.new(params[:remote_key])

    respond_to do |format|
      if @remote_key.save
        @remote_key.encrypt_key_content(@remote_key.ssh_key.file.read, :key => params[:key])
        @remote_key.save
        format.html { redirect_to @remote_key, notice: 'Remote key was successfully created.' }
        format.json { render json: @remote_key, status: :created, location: @remote_key }
      else
        format.html { render action: "new" }
        format.json { render json: @remote_key.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /remote_keys/1
  # DELETE /remote_keys/1.json
  def destroy
    get_context!
    @remote_key.destroy

    respond_to do |format|
      format.html { redirect_to remote_keys_path }
      format.json { head :no_content }
    end
  end

  protected
  def get_context
    @remote_key = RemoteKey.find_by_name(params[:name]) if params[:name]
    @remote_key = RemoteKey.find(params[:id]) if @remote_key.nil?
  end

  def get_context!
    get_context
    raise NotFoundError if @remote_key.nil?
  end
end
