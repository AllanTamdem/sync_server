Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  config.serve_static_assets = false

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Generate digests for assets URLs.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Set to :debug to see everything in the log.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  #config.action_mailer.default_url_options = { host: 'orange-mediaspot-sync.herokuapp.com' }

  config.allow_concurrency = true

  config.middleware.delete Rack::Lock
  
  config.domain = 'syncserverstaging.tapngo.orangejapan.jp'

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
  # config.alert_admin_emails = ["vincent.auvray@orange.com"]

  #### End Email config

  #### Start AWS S3 config
  config.aws_access_key_id = 'AKIAIDX5DZOPNU53XVOQ'
  config.aws_secret_access_key = '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'
  config.aws_region = 'eu-west-1'
  config.aws_bucket = 'orange-fcd'
  config.aws_sqs_s3_events = 'Orange-FCD_S3-events'
  #### End AWS S3 config

  #### Logs
  config.logentries_token = 'b4ead1c5-eafc-4fdb-8d5b-4d07603008bf'

  #### APIs
  config.tr069_api_host = '52.16.103.212'
  config.tr069_api_port = 7557
  config.node_ws_api = 'http://52.17.226.202:3052' # consume the api on prod
  config.labgency_api = 'http://127.0.0.1:3549'

  ### SMS config
  config.twilio_account_sid = 'AC083447a9562d41da3c5aed512186af2d'
  config.twilio_auth_token = '54f182a0c767599725e1bae40f5ce3e9'
  config.twilio_from = '+16467621335'
  config.twilio_status_callback = "https://#{config.domain}/sms_status/update" #twilio will post the status of the sms there

  ### tr069 redis pub/sub
  config.tr069_pubsub_scope = 'pubsub_tr069'
  config.tr069_pubsub_host = '52.16.103.212' 
  config.tr069_pubsub_port = 6379

end
