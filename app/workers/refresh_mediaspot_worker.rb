class RefreshMediaspotWorker
  include Sidekiq::Worker

  sidekiq_options retry: false
  
  require 'date'

  include Tr069Helper

  def perform mediaspot_id

		tr069_refresh_device(mediaspot_id)

  end

end