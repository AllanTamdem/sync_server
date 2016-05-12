Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  #config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.allow_concurrency = true

  config.middleware.delete Rack::Lock

  config.domain = 'localhost:3000'

  #### Start Email config

  # ActionMailer Config
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { :host => "#{config.domain}" }
  
  config.action_mailer.smtp_settings = {
    :address   => "email-smtp.eu-west-1.amazonaws.com",
    :port      => 587, 
    :user_name => "AKIAI37DCKO3WPH2DOSA",
    :password  => "Ani3tP9OeJMxnTB84tRzEFDhqZReH4yxUKw+2u09Ncb6",
    :authentication => :plain
  }

  config.alert_email_from = "\"Orange FCD - Alerts\" <noreply@#{config.domain}>"  
  config.alert_admin_emails = []
  # config.alert_admin_emails = ["julien.sansot@gmail.com"]

  #### End Email config

  #### Start AWS S3 config
  config.aws_access_key_id = 'AKIAIDX5DZOPNU53XVOQ'
  config.aws_secret_access_key = 'oLwRyLSk2vFUuZI41tTVRqMYdGt682jDTMGVpSJm'
  config.aws_region = 'eu-west-1'
  config.aws_bucket = 'orange-fcd'
  config.aws_endpoint = 'http://localhost:10453' #fake S3
  config.aws_sqs_s3_events = 'Orange-FCD_S3-events'
  #### End AWS S3 config

  #### Logs
  config.logentries_token = 'f99c78ae-89e6-4f48-ae34-ddc082164219'

  #### APIs
  config.tr069_api_host = '52.16.103.212'
  config.tr069_api_port = 7557
  config.node_ws_api = 'http://52.17.226.202:3052'
  config.labgency_api = 'http://52.17.226.202:3549'

  ### SMS config
  config.twilio_account_sid = 'AC083447a9562d41da3c5aed512186af2d'
  config.twilio_auth_token = '54f182a0c767599725e1bae40f5ce3e9'
  config.twilio_from = '+16467621335'
  config.twilio_status_callback = "https://#{config.domain}/sms_status/update" #twilio will post the status of the sms there

  ### tr069 redis pub/sub
  config.tr069_pubsub_scope = 'pubsub_tr069'
  config.tr069_pubsub_host = '127.0.0.1'
  config.tr069_pubsub_port = 6379

  config.react.variant = :development
end

