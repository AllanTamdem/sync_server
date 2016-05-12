

$redis = Redis::Namespace.new("syncserver", :redis => Redis.new(driver: :hiredis))