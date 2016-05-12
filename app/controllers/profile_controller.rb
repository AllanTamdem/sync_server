class ProfileController < ApplicationController


  def index 
  	unless user_signed_in?
		render :status => 404
  	else 
  		@user = current_user
  		if(request.post?)

  			if params[:user][:subscribed_alert_mediaspot_offline] or
          params[:user][:subscribed_alert_sync_error] or
          params[:user][:sms_subscribed_alert_mediaspot_offline] or
          params[:user][:sms_subscribed_alert_sync_error] or
          params[:user][:phone_number]
  				update_user_notifications @user
  			else
  				update_user_password @user
  			end

  		end
  	end
  end


  private
	  def update_user_password user

	  	password_current = params[:user][:password]
	  	password_new = params[:user][:password_new]
	  	password_new_confirmation = params[:user][:password_new_confirmation]

	  	unless current_user.valid_password?(password_current)
	  		user.errors.add(:password, "incorrect.")
	  	else
	  		if(r = user.update(password: password_new, password_confirmation: password_new_confirmation))
          save_profile_log(user.email, 'change_password', {}.to_json)
  				flash[:notice] = "Password successfully updated"
	  		end
	  	end
	  	
	  end

	  def update_user_notifications user

    	pa = params.require(:user).permit(:subscribed_alert_mediaspot_offline,
        :subscribed_alert_sync_error, :sms_subscribed_alert_mediaspot_offline,
        :sms_subscribed_alert_sync_error, :phone_number)

      @user.update(pa)


      save_profile_log(user.email, 'update_notifications', pa.to_json)
	  	
	  end

end