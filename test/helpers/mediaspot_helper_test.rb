
# rake test test/helpers/mediaspot_helper_test.rb

class MediaspotHelperTest < ActionView::TestCase


# 
# Testing mediaspot_set_ziped_value
# 
# 	
  test "should return a decoded decompressed correct value" do
  	test_text = "this is a correct value"
  	encoded_ziped_value = Base64.encode64(ActiveSupport::Gzip.compress(test_text))

  	client = {'TestValue' => { '_value' =>  encoded_ziped_value }}

		mediaspot_set_ziped_value(client, 'TestValue')

    assert_equal test_text, client['TestValue']['_value']
  end


  test "should return a an empty output for an empty input" do

  	client = {'TestValue' => { '_value' =>  '' }}

		mediaspot_set_ziped_value(client, 'TestValue')

    assert_equal '', client['TestValue']['_value']
  end

  test "should return a an empty output for a nil input" do

  	client = {'TestValue' => { '_value' =>  nil }}

		mediaspot_set_ziped_value(client, 'TestValue')

    assert_equal '', client['TestValue']['_value']
  end

  test "should return a an empty output for a missing input" do

  	client = {}

		mediaspot_set_ziped_value(client, 'TestValue')

    assert_equal false, client.include?('TestValue')
  end


# 
# Testing mediaspot_set_syncing_status
# 
# 	




end