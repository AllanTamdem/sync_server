# rake test test/helpers/sms_helper_test.rb

class Fakes3Test < ActionView::TestCase


  test "should just test stuff" do

    s3_client = Aws::S3::Client.new(
        access_key_id: '123',
        secret_access_key: 'abc',
        region: 'region',
        endpoint: 'http://localhost:10453/',
        force_path_style: true,
        ssl_verify_peer: false
    )

    File.open('test/fakes3_test.rb', 'r') do |file|
    	s3_client.put_object(bucket: 'orange-fcd', key: 'fakes3-test-file', body: file)
    end
    # s3_client.list_buckets().buckets.each do |bucket|
    #   puts "Deleting bucket #{bucket.name}"

    # bucket = Aws::S3::Resource.new(
    #     client: s3_client)
    #              .bucket('orange-fcd')
    # # #
    # bucket.objects.each do |object|
    #   puts 'Damn>> ' + object.key
    #   resp = s3_client.delete_object(
    #       {bucket: 'orange-fcd',
    #        key: object.key}
    #   )
    # end

    # s3_client.delete_bucket({bucket: bucket.name})
    # end
    #
    # puts "Creating a new bucket"
    # if bucket.nil
    #   s3_client.create_bucket({bucket: 'orange-fcd'})
    #   puts s3_client.list_buckets().buckets
    # end
    # assert_equal 0, s3_client.list_buckets().buckets.count

  end

end