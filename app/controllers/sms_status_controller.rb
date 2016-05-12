class SmsStatusController < ApplicationController
  protect_from_forgery with: :null_session

	before_action :authenticate_user!, only: [:index]
	before_action :only_admin, only: [:index]

	def index

		@sms_statuses = SmsStatus.order('id desc').page(params[:page])

	end

	def update

		params_sms_status = params.except(:action, :controller)
		params_sms_status[:date] = DateTime.now

		sms_status = SmsStatus.find_by sms_id: params['SmsSid']

		if sms_status == nil

      SmsStatus.create!(
        sms_id: params['SmsSid'],
        status_information: [params_sms_status].to_json
      )

		else

			status_information = []

			if sms_status.status_information.blank? == false
				status_information = JSON.parse(sms_status.status_information)
			end
			
			status_information << params_sms_status

      sms_status.update!(
        status_information: status_information.to_json
      )

		end

		render :json => { status: 'done' }

	end

	def only_admin

		unless current_user.try(:admin?)
		  redirect_to root_path
		end

	end

end