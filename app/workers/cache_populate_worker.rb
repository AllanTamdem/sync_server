class CachePopulateWorker

  include Tr069Helper
  include CacheHelper

  def perform

		mediaspots = tr069_get_devices

		log "populating analytics cache"
		cache_populate_analytics(mediaspots)

  end

  private

  	def log txt
			Rails.logger.info("CachePopulateWorker_LOGGER ----- " + txt.to_s)
  	end

end