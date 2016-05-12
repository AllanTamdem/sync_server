class MonitoringWorker

  require 'date'

  include Tr069Helper
  include MediaspotHelper
  include UsersHelper
  include SmsHelper
  include WorkersHelper

  def perform
    return "runs only in production" if false == Rails.env.production?

		cron_log "----STARTING MonitoringWorker"

		mediaspots = tr069_get_devices()

		mediaspots.each{ |mediaspot|

      monitor_online_status(mediaspot)

      clients = mediaspot_get_clients(mediaspot)

      clients.each{ |client|

          monitor_sync_errors(client)

      }

      # monitor_memory_usage(mediaspot)
		}
  	
		cron_log "----ENDING MonitoringWorker"

		nil

  end


  def monitor_memory_usage mediaspot
    system_info = mediaspot_set_ziped_value(mediaspot['InternetGatewayDevice']['X_orange_tapngo'], 'SystemMonitor')

    memory_line = system_info.lines.find{|l| l.start_with?('KiB Mem' )}
    #todo check if memory_line is not null
    memory_total = /(\d+) total/.match(memory_line)[1].to_f
    memory_used = /(\d+) used/.match(memory_line)[1].to_f
    memory_percent_used = (memory_used / memory_total * 100).round(2)

    swap_line = system_info.lines.find{|l| l.start_with?('KiB Swap' )}
    swap_total = /(\d+) total/.match(swap_line)[1].to_f
    swap_used = /(\d+) used/.match(swap_line)[1].to_f

    if swap_total > 0
      swap_percent_used = (swap_used / swap_total * 100).round(2)
    end

    # log mediaspot['mediaspotName'] +
    # " | Mem used: " + memory_percent_used.to_s + '%' +
    # " | Swap used: " + (swap_percent_used || 0).to_s + '%'

  end

  def monitor_sync_errors client

    sync_log = mediaspot_set_ziped_value(client, 'RepoSyncLog')
    mediaspot_set_syncing_status(client)

    alert = Alert.find_by(
      type_alert: Alert::Sync_error,
      mediaspot_id: client['mediaspot_id'],
      mediaspot_client_name: client['client_name'],
      resolved_at: nil,
    )

    if client['sync_error'] == false

      if client['syncing'] == true
        return
      end

      if alert != nil
        information = JSON.parse(alert.information)
        information << sync_log
        alert.update!(
          resolved_at: DateTime.now,
          information: information.to_json
        )
        log("resolve alert #{alert.inspect}")        

        extra_text = "sync log : \n" + sync_log + "\n\n"

        manage_alert(alert, [client['client_name']], extra_text)
      end

      return
    end

    extra_text = nil

    if alert == nil

      sync_if_needed(client['mediaspot_id'], client['client_number'])

      alert = Alert.create!(
        type_alert: Alert::Sync_error,
        mediaspot_id: client['mediaspot_id'],
        mediaspot_name: client['mediaspot_name'],
        mediaspot_client_name: client['client_name'],
        mediaspot_client_number: client['client_number'],
        sent_count: 0,
        information: [sync_log].to_json
      )
      log("create alert #{alert.inspect}")

      extra_text = "sync log : \n" + sync_log + "\n\n" +
      'The synchronization process is going to be retried.'

    end

    manage_alert(alert, [client['client_name']], extra_text)

  end


  def monitor_online_status mediaspot

    alert = Alert.find_by(
      type_alert: Alert::Mediaspot_offline,
      mediaspot_id: mediaspot['_id'],
      resolved_at: nil,
    )

    last_inform = mediaspot['date_last_inform']

    is_online = nil

    if mediaspot['websocket'] == true
      is_online = time_ago_in_seconds(last_inform) < 12*60 # 12mn with websocket
    else
      is_online = time_ago_in_seconds(last_inform) < 31*60 # 31mn with tr69
    end

    if is_online == true

      if alert != nil 

        alert.update!(resolved_at: DateTime.now)
        log("resolve alert #{alert.inspect}")

      end

      return
    end

    if alert == nil

      alert = Alert.create!(
        type_alert: Alert::Mediaspot_offline,
        mediaspot_id: mediaspot['_id'],
        mediaspot_name: mediaspot['mediaspotName'],
        sent_count: 0
      )
      log("create alert #{alert.inspect}")

    end

    manage_alert(alert, mediaspot_get_clients_names(mediaspot))
      
  end


  private 

    def manage_alert alert, client_names, extra_text = nil

      sent_count = alert[:sent_count]

      if alert.resolved_at != nil

        email_report = send_email(alert, client_names, extra_text)
        sms_report = send_sms(alert, client_names)

        alert.update!(
          last_sent_at: DateTime.now,
          last_sent_to: [email_report[:sent_to], sms_report[:sent_to]].select{|x| x.blank? == false}.join(' and '),
          sent_count: sent_count + 1
        )


        return
      end

      if sent_count == 0

        email_report = send_email(alert, client_names, extra_text)
        sms_report = send_sms(alert, client_names)

        alert.update!(
          last_sent_at: DateTime.now,
          last_sent_to: [email_report[:sent_to], sms_report[:sent_to]].select{|x| x.blank? == false}.join(' and '),
          sent_count: sent_count + 1
        )


        return
      end

      days_since_last_email_sent = (DateTime.now - alert[:last_sent_at].to_datetime).to_i

      # after one day
      # or every week
      if (sent_count == 1 and 1 == days_since_last_email_sent) or
        (sent_count > 1 and days_since_last_email_sent == (sent_count - 1 ) * 7)

        email_report = send_email(alert, client_names, extra_text)

        alert.update!(
          last_sent_at: DateTime.now,
          last_sent_to: email_report[:sent_to],
          sent_count: sent_count + 1
        )

        return
      end

    end

    def send_sms alert, client_names

      user_condition = {sms_subscribed_alert_mediaspot_offline: true}
      if alert.type_alert == Alert::Sync_error
        user_condition = {sms_subscribed_alert_sync_error: true}
      end

      users_to_notify = get_users_per_client_names(client_names, user_condition)

      users_phone_numbers = users_to_notify.map{|u| u[:phone_number] }.select{|number| number != nil}

      message = nil

      if alert.type_alert == Alert::Sync_error
        if alert.resolved_at == nil
          message = "Orange Fast Content Download. A synchronization error happened " + 
          "on the mediaspot #{alert.mediaspot_name} on the client #{alert.mediaspot_client_name}."
        else
          message = "RESOLVED. Orange Fast Content Download. The synchronization error has been resolved " + 
          "on the mediaspot #{alert.mediaspot_name} on the client #{alert.mediaspot_client_name}."
        end
      elsif alert.type_alert == Alert::Mediaspot_offline        
        if alert.resolved_at == nil
          message = "Orange Fast Content Download. The mediaspot #{alert.mediaspot_name} (#{alert.mediaspot_id})" +
          " is offline."
        else
          message = "RESOLVED. Orange Fast Content Download. The mediaspot #{alert.mediaspot_name} (#{alert.mediaspot_id})" +
          " is back online."
        end
      end

      if message != nil
        users_phone_numbers.each{|phone_number|
          if phone_number.blank? == false
            result_sms = sms_send_message(phone_number, message)
            if result_sms[:error] != nil
              cron_log "error sending message to #{phone_number} : #{result_sms[:error]}"
              log_error "error sending message to #{phone_number} : #{result_sms[:error]}"
            end
          end
        }
        cron_log "sms sent to #{users_phone_numbers.to_sentence}: #{message}"
      end

      sms_report = {
        sent_to: users_phone_numbers.join(', '),
        message: message
      }

      sms_report

    end


    def send_email alert, client_names, extra_text = nil

      user_condition = {subscribed_alert_mediaspot_offline: true}

      if alert.type_alert == Alert::Sync_error
        user_condition = {subscribed_alert_sync_error: true}
      end

      users_to_notify = get_users_per_client_names(client_names, user_condition)
      users_emails = users_to_notify.map{|u| u[:email] }

      emails = Rails.configuration.alert_admin_emails + users_emails

      subject = "Alert "

      if alert.resolved_at != nil
       subject = "Alert resoved "
      end

      subject += " : #{alert.type_alert} - #{alert.mediaspot_name}   #{alert.mediaspot_client_name}"

      message = ""

      if alert.resolved_at != nil
        message += "This alert has been resolved \n\n"
      end

      message += "Orange FCD alert\n"
      message += "Alert type: #{alert.type_alert}\n"
      message += "Mediaspot: #{alert.mediaspot_name} (#{alert.mediaspot_id})\n"

      if alert[:mediaspot_client_name] != nil
        message += "Client: #{alert.mediaspot_client_name} \n"
      end

      if extra_text != nil
        message += extra_text
      end

      if alert[:sent_count] > 0
        message += "\n\n(this message is the #{alert[:sent_count]+1}#{(alert[:sent_count]+1).ordinal}  notification about this alert)"
      end

      email_report = {
        sent_from: Rails.configuration.alert_email_from,
        sent_to: emails.join(', '),
        subject: subject,
        message: message
      }

      emails.each do |email|
        ActionMailer::Base.mail(
          from: email_report[:sent_from],
          to: email,
          subject: email_report[:subject],
          body: email_report[:message]).deliver
      end

      cron_log "email sent #{email_report.inspect}"

      email_report
    end

    def time_ago_in_seconds date
      return ((DateTime.now - date)  * 24 * 60 * 60).to_i
    end


  	def cron_log txt
  		p Time.now.to_s + ' -- ' + txt.to_s
  		log txt
  	end


  	def log_error txt
			Rails.logger.fatal("MonitoringWorker_LOGGER ----- " + txt.to_s)
  	end

  	def log txt
			Rails.logger.info("MonitoringWorker_LOGGER ----- " + txt.to_s)
  	end


end