class SiteSettingsController < ApplicationController
  before_action do
    unless current_user.try(:admin?)
      redirect_to root_path
    end
  end

  def index

  	@settings = SiteSettings.first
  	if @settings == nil
		  @settings = SiteSettings.create(metadata_template: '[]')
  	end

    @t069_host_white_list = @settings[:tr069_host_white_list]

  end

  def update_metadata_template 

  	settings = SiteSettings.first

  	p = params.require(:site_settings).permit(:metadata_template)

  	begin
  		parsed = JSON.parse(p[:metadata_template])
  	rescue
    	flash[:alert] = "Error: Metadata template must be valid json"
    	redirect_to action: :index
    	return
  	end


    respond_to do |format|
      if settings.update(params.require(:site_settings).permit(:metadata_template))

        save_site_settings_log(current_user.email, 'update_metadata_template',
          params.require(:site_settings).permit(:metadata_template).to_json
        )

    	  flash[:notice] = "The metadata template were successfully updated."
        format.html { redirect_to action: :index }
      else
        flash[:alert] = "Error while saving the metadata template"
        format.html { redirect_to action: :index }
      end
    end
  end

  def update_super_admins

    if params['site_settings']['super_admins'].split(',').map{|e| e.strip}.include?(current_user.email)
      
      settings = SiteSettings.first

      if settings.update(params.require(:site_settings).permit(:super_admins))      
        save_site_settings_log(current_user.email, 'update_super_admins',
          params.require(:site_settings).permit(:super_admins).to_json
        )
        flash[:notice] = "The Super Admins list were successfully updated."
        redirect_to action: :index
      else
        flash[:notice] = "Error while saving the Super Admins list"
        redirect_to action: :index
      end
    else
      flash[:alert] = "You can't remove yourself from super admin"
      redirect_to action: :index
    end

  end

  def update_tr69_hosts_whitelist

    settings = SiteSettings.first

    respond_to do |format|
      if settings.update(params.require(:site_settings).permit(:tr069_hosts_white_list))

        save_site_settings_log(current_user.email, 'update_tr69_hosts_whitelist',
          params.require(:site_settings).permit(:tr069_hosts_white_list).to_json
        )

        flash[:notice] = "The TR069 hosts white list were successfully updated."
        format.html { redirect_to action: :index }
      else
        flash[:alert] = "Error while saving the TR069 hosts white list"
        format.html { redirect_to action: :index }
      end
    end
  end

  def update_websocket_hosts_whitelist

    settings = SiteSettings.first

    respond_to do |format|
      if settings.update(params.require(:site_settings).permit(:websocket_hosts_white_list))

        save_site_settings_log(current_user.email, 'update_websocket_hosts_whitelist',
          params.require(:site_settings).permit(:websocket_hosts_white_list).to_json
        )

        flash[:notice] = "The WebSocket hosts white list were successfully updated."
        format.html { redirect_to action: :index }
      else
        flash[:alert] = "Error while saving the WebSocket hosts white list"
        format.html { redirect_to action: :index }
      end
    end

  end

  def update_metadata_validation_schema

    settings = SiteSettings.first

    p = params.require(:site_settings).permit(:metadata_validation_schema)

    begin
      parsed = JSON.parse(p[:metadata_validation_schema])
    rescue
      flash[:alert] = "Error: Metadata validation schema must be valid json"
      redirect_to action: :index
      return
    end


    respond_to do |format|
      if settings.update(params.require(:site_settings).permit(:metadata_validation_schema))

        save_site_settings_log(current_user.email, 'update_metadata_validation_schema',
          params.require(:site_settings).permit(:metadata_validation_schema).to_json
        )

        flash[:notice] = "The metadata validation schema were successfully updated."
        format.html { redirect_to action: :index }
      else
        flash[:alert] = "Error while saving the metadata validation schema"
        format.html { redirect_to action: :index }
      end
    end
  end

end