class HelpersController < ApplicationController
	
	before_action :authenticate_user!

	include GlobalHelper


	def generate_api_key
		unless current_user.admin?
		  	render :status => 404
		else
			render :json => {key: genereate_api_key}
		end
	end

end