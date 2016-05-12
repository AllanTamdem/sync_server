class SaveApplicationLogWorker
  include Sidekiq::Worker

  require 'date'

  def perform user, action_type, action, details
  	ApplicationLog.create!(
			time: Time.now,
			user: user,
			action_type: action_type,
      action: action,
			details: details
		)		
  end


end


  # field :time, type: DateTime
  # field :log_type, type: String
  # field :user, type: String
  # field :description, type: String