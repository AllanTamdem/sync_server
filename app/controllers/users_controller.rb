class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action do
    unless current_user.try(:admin?)
      redirect_to root_path
    end
  end

  include GlobalHelper


  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
      
    pa = params.require(:user).permit(:email, :password, :password_confirmation, :phone_number,
      :admin, :content_provider_id,
      :subscribed_alert_mediaspot_offline, :subscribed_alert_sync_error,
      :sms_subscribed_alert_mediaspot_offline, :sms_subscribed_alert_sync_error)

    pa[:api_key] = genereate_api_key

    @user = User.new(pa)
    
    respond_to do |format|
      if @user.save

        content_providers = []

        (params[:user][:content_provider_ids] || []).each do |k|
          id = k.to_i
          if id > 0
            content_providers << ContentProvider.find(id)
          end
        end
        @user.content_providers = content_providers

        save_users_log(current_user.email, 'user_created', {
          user: @user,
          content_providers: content_providers.map{|cp| { id: cp[:id], name: cp[:name] }}
        }.to_json)

        format.html { redirect_to @user, notice: 'User was successfully created.' }
      else
        format.html { render :new }
      end
    end

  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
      
    pa = params.require(:user).permit(:admin, :api_key, :phone_number,
      :subscribed_alert_mediaspot_offline, :subscribed_alert_sync_error,
      :sms_subscribed_alert_mediaspot_offline, :sms_subscribed_alert_sync_error)

    respond_to do |format|
      if @user.update(pa)

        content_providers = []

        (params[:user][:content_provider_ids] || []).each do |k|
          id = k.to_i
          if id > 0
            content_providers << ContentProvider.find(id)
          end
        end
        @user.content_providers = content_providers

        save_users_log(current_user.email, 'user_updated', {
          user: @user,
          content_providers: content_providers.map{|cp| { id: cp[:id], name: cp[:name] }}
        }.to_json)

        format.html { redirect_to @user, notice: 'User was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy

    @user.destroy

    save_users_log(current_user.email, 'user_deleted',@user.to_json)

    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully deleted.' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params[:user]
    end
end
