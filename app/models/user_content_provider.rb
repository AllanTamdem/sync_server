class UserContentProvider < ActiveRecord::Base
	belongs_to :user  
	belongs_to :content_provider
end
