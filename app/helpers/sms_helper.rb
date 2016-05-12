module SmsHelper


	def sms_send_message to, body

		twilio_client = Twilio::REST::Client.new(
			Rails.configuration.twilio_account_sid,
			Rails.configuration.twilio_auth_token)

		begin		 
			result = twilio_client.account.messages.create({
				:from => Rails.configuration.twilio_from, 
				:to => to.gsub(" ",""), 
				:body => body,
				:status_callback => Rails.configuration.twilio_status_callback
			})

	    SmsStatus.create!(
	      sms_id: result.sid,
	      sent_information: {to: to, body: body}.to_json
	    )

	    return {error: nil}

		rescue Twilio::REST::RequestError => e

	    return {error: e.message}

		end

	end


	def is_phone_number_valid? phone_number

		lookup_client = Twilio::REST::LookupsClient.new(
			Rails.configuration.twilio_account_sid,
			Rails.configuration.twilio_auth_token)

		begin

			response = lookup_client.phone_numbers.get(phone_number.gsub(" ",""))
			response.phone_number #if invalid, throws an exception. If valid, no problems.
			return true

		rescue => e

			if e.code == 20404
				return false
	    else
	      raise e
	    end

    end

	end

end


