module GlobalHelper

	def genereate_api_key
		SecureRandom.urlsafe_base64
	end

end