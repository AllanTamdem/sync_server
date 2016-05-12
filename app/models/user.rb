class User < ActiveRecord::Base


  include SmsHelper


  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :trackable, :validatable

  devise :database_authenticatable, #:registerable,
         :recoverable, :rememberable, :trackable, :validatable
         
  belongs_to :content_provider

  has_many :user_content_providers, :dependent => :destroy
  has_many :content_providers, :through => :user_content_providers

	
	validate :validate_phone_number

	private
  
 
  def validate_phone_number

    unless self.phone_number.blank?

      if self.phone_number.start_with?('+')

        unless is_phone_number_valid?(self.phone_number)

          errors.add(:phone_number, ". #{self.phone_number} is not recognized as a valid phone number")

        end        

      else

        errors.add(:phone_number, "must start with '+'")

      end

    end

  end

end