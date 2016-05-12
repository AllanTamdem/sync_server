# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, "log/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever


# 10 minutes after every hour
every '10 * * * *' do
  runner "RefreshMediaspotsWorker.new.perform"
end

# 15 minutes after every hour
every '15 * * * *' do
  runner "SaveAnalyticsWorker.new.perform_all"
end

# 25 minutes after every hour
every '25 * * * *' do
  runner "SaveFileTypeForAnalyticsWorker.new.perform_all"
end

# every day at 2am and 2pm
every '0 2,14 * * *' do
  runner "LabgencyApplyCidWorker.new.perform"
end

# every minute
every '* * * * *' do
  runner "MonitoringWorker.new.perform"
end