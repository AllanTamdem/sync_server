class ContentProvidersController < ApplicationController
  before_action :set_content_provider, only: [:show, :edit, :update, :destroy]
  before_action do
    unless current_user.try(:admin?)
      redirect_to root_path
    end
  end

  Hidden_aws_secret = '###SECRETKEY###'

  # GET /content_providers
  # GET /content_providers.json
  def index
    @content_providers = ContentProvider.all
  end

  # GET /content_providers/1
  # GET /content_providers/1.json
  def show
  end

  # GET /content_providers/new
  def new
    @content_provider = ContentProvider.new
  end

  # GET /content_providers/1/edit
  def edit
  end

  # POST /content_providers
  # POST /content_providers.json
  def create
    @content_provider = ContentProvider.new(content_provider_params)

    respond_to do |format|
      if @content_provider.save

        save_content_providers_log(current_user.email, 'content_provider_created',
          @content_provider.to_json(except: [ :aws_bucket_secret_access_key ])
        )

        format.html { redirect_to @content_provider, notice: 'Content provider was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /content_providers/1
  # PATCH/PUT /content_providers/1.json
  def update

    pp = content_provider_params

    if pp[:aws_bucket_secret_access_key] == Hidden_aws_secret
      pp["aws_bucket_secret_access_key"] = ContentProvider.find(params[:id])[:aws_bucket_secret_access_key]
    end

    respond_to do |format|
      if @content_provider.update(pp)

        save_content_providers_log(current_user.email, 'content_provider_updated',
          @content_provider.to_json(except: [ :aws_bucket_secret_access_key ])
        )

        format.html { redirect_to @content_provider, notice: 'Content provider was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /content_providers/1
  # DELETE /content_providers/1.json
  def destroy
    if @content_provider.users.any?
        msg = "You need to remove the users from \"#{@content_provider.name}\" before deleting this content provider."
        respond_to do |format|
          format.html { redirect_to content_providers_url, alert: msg}
        end
    else
      @content_provider.destroy

      save_content_providers_log(current_user.email, 'content_provider_deleted',
        @content_provider.to_json(except: [ :aws_bucket_secret_access_key ])
      )

      respond_to do |format|
        format.html { redirect_to content_providers_url, notice: 'Content provider was successfully destroyed.' }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_content_provider
      @content_provider = ContentProvider.find(params[:id])      
      if @content_provider[:aws_bucket_secret_access_key].blank? == false
        @content_provider[:aws_bucket_secret_access_key] = Hidden_aws_secret
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def content_provider_params

      params.require(:content_provider).permit(:name, :description,
        :technical_name, :path_in_bucket, :unzipping_files,
        :aws_bucket_access_key_id, :aws_bucket_secret_access_key,
        :aws_bucket_region, :aws_bucket_name)
      
    end
end
