class ContentProvider < ActiveRecord::Base

	validates :technical_name, uniqueness: true
	validates :name, presence: true, uniqueness: true
	
	validate :technical_name_cannot_be_blank_or_slash

	attr_accessor :flash_alert

	before_destroy :chek_no_users


	has_many :user_content_providers, :dependent => :destroy  
	has_many :users, :through => :user_content_providers

	private
		def chek_no_users

		  return true if users.count == 0

		  false
		end
 
	  def technical_name_cannot_be_blank_or_slash
	    if technical_name.blank? or technical_name.strip == '/' or technical_name.strip == '\\'
	      errors.add(:technical_name, "can't be blank or slash")
	    end
	  end
end