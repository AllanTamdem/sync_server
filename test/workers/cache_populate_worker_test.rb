
# bundle exec rake test test/workers/cache_populate_worker_test.rb

class CachePopulateWorkerTest < ActionView::TestCase

  test "should populate all the analytics in redis" do

  	CachePopulateWorker.new.perform

    assert_equal "test", "test"
  end


end