class AlertsController < ApplicationController

	before_action :authenticate_user!
	before_action :only_admin

	def index

		@alerts = Alert.order('id desc').page(params[:page])

	end

	def only_admin

		unless current_user.try(:admin?)
		  redirect_to root_path
		end

	end

end