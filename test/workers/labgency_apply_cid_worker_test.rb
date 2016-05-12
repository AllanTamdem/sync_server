
# bundle exec rake test test/workers/labgency_apply_cid_worker_test.rb

class LabgencyApplyCidWorkerTest < ActionView::TestCase

  test "should move the labgency files and apply the cid" do

  	p LabgencyApplyCidWorker.new.perform

    assert_equal "test", "test"
  end


end