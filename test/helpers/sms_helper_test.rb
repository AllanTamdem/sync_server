
# rake test test/helpers/sms_helper_test.rb

class SmsHelperTest < ActionView::TestCase


  test "should just test stuff" do

  	result = sms_send_message('+818099822428','qwerty')

  	p result[:error]

  	p SmsStatus.all.inspect

  	assert_equal true, true
  end

end