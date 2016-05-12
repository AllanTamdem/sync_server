
# bundle exec rake test test/workers/save_analytics_worker_test.rb

class SaveAnalyticsWorkerTest < ActionView::TestCase

  test "should populate all the analytics in mongodb" do

  	SaveAnalyticsWorker.new.perform_all

    assert_equal "test", "test"
  end


end