class ApidocController < ApplicationController
	
	before_action :authenticate_user!

	def index

		@protocol = request.protocol
		@host = request.host_with_port

		@api_key = current_user.api_key

	end
	
end