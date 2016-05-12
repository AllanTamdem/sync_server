
# rake test test/helpers/metadata_helper_test.rb

class MetadataHelperTest < ActionView::TestCase
 
  test "should return couldn't parse empty string" do
  	json = ""
    errors = metadata_validate json

    assert_not_empty errors
    assert_equal "invalid JSON", errors[0] 
  end
 
  test "should return couldn't parse nil" do
  	json = nil
    errors = metadata_validate json

    assert_not_empty errors
    assert_equal "invalid JSON", errors[0] 
  end

 
  test "should return X is not present" do
  	json = '{}'
    errors = metadata_validate json

    assert_not_empty errors
    assert errors.include?('The "id" value is mandatory')
    assert errors.include?('The "type" value is mandatory')
    assert errors.include?('The "typeLabel" value is mandatory')
    assert errors.include?('The "validationPlatform" value is mandatory')
    assert errors.include?('The "mimeType" value is mandatory')
    assert errors.include?('The "contentSponsor" value is mandatory')
  end

 
 # NO ERRORS

  test "should return no errors. 1" do
  	json = '{"id": "test", "title": "test", "type": "newspaper", "typeLabel": "test",'
  	json += '"validationPlatform": "labgency", "mimeType": "test", "contentSponsor": "text", '
  	json += '"validationPlatformData": {"cid":"test"}, '
    json += '"number": "test", "editor": "test", '
    json += '"description": "test", "imageUrl": "test", '
    json += '"size": "test", "releaseDate": "test", '
    # json += '"inCatalogueFrom": "test", "inCatalogueUntil": "test" '
    json += '"adImageUrl": "test", "adWebSiteUrl": "test", '
  	json += '"isPromo": "false" '
  	json += '}'

    errors = metadata_validate json
    assert_empty errors
  end

 
 # VALIDATION PLATFORM ERRORS

  test "should return wrong validationPlatform error" do
  	json = '{"id": "test", "type": "test", "typeLabel": "test",'
  	json += '"validationPlatform": "test", "mimeType": "test", "contentSponsor": "text"}'

    errors = metadata_validate json

    assert_not_empty errors
    assert errors.include?('"validationPlatform" must be either "orange" or "labgency"')
  end

  test "should return validationPlatformData error 1" do
  	json = '{"id": "test", "type": "test", "typeLabel": "test",'
  	json += '"validationPlatform": "orange", "mimeType": "test", "contentSponsor": "text", '
  	json += '"validationPlatformData": {"cid":"test"}'
  	json += '}'

    errors = metadata_validate json
    
    assert_not_empty errors
    assert errors.include?('For the "orange" validationPlatform, the "validationPlatformData.mediaUrl" is mandatory')
  end 

  test "should return validationPlatformData error 2" do
  	json = '{"id": "test", "type": "test", "typeLabel": "test",'
  	json += '"validationPlatform": "labgency", "mimeType": "test", "contentSponsor": "text", '
  	json += '"validationPlatformData": {"mediaUrl":"test"}'
  	json += '}'

    errors = metadata_validate json
    
    assert_not_empty errors
    assert errors.include?('For the "labgency" validationPlatform, the "validationPlatformData.cid" is mandatory')
  end 

  test "should return validationPlatformData error 3" do
  	json = '{"id": "test", "type": "test", "typeLabel": "test",'
  	json += '"validationPlatform": "labgency", "mimeType": "test", "contentSponsor": "text", '
  	json += '"validationPlatformData": {"mediaUrl":"test", "cid":"test"}'
  	json += '}'

    errors = metadata_validate json
    
    assert_not_empty errors
    assert errors.include?('For the "labgency" validationPlatform, validationPlatformData must only contains "cid"')
  end 

 
 # CONTENT TYPE ERRORS

  test "should return wrong type error" do
  	json = '{"id": "test", "type": "test", "typeLabel": "test",'
  	json += '"validationPlatform": "labgency", "mimeType": "test", "contentSponsor": "text" '
  	json += '}'

    errors = metadata_validate json

    assert_not_empty errors
    assert errors.include?('"type" must be either "movie", "series", "book", "newspaper" or "music"')
  end

 
 # INTEGER TYPE ERRORS

  test "should return integer error" do
  	json = '{"id": "test", "type": "music", "typeLabel": "test",'
  	json += '"validationPlatform": "labgency", "mimeType": "test", "contentSponsor": "text", '
  	json += '"validationPlatformData": {"cid":"test"}, '
  	json += '"author": "test", "editor": "test", "duration": "test" '
  	json += '}'

    errors = metadata_validate json

    assert_not_empty errors
    assert errors.include?('"duration" must be an integer')
  end


end