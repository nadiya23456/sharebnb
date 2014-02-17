# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  fname           :string(255)      not null
#  lname           :string(255)      not null
#  gender          :string(255)
#  bday            :date
#  session_token   :string(255)
#  email           :string(255)      not null
#  phone           :string(255)
#  password_digest :string(255)      not null
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class User < ActiveRecord::Base
  attr_accessible :fname, :lname, :gender, :bday, :email, :phone, :description, :password, :password_confirmation
  attr_reader :password, :password_confirmation
  
  before_validation :ensure_session_token
  
  validates :fname, presence: {message: "First name can't be blank"}
  validates :lname, presence: {message: "Last name can't be blank"}
  validates :password_digest, presence: {message: "Password can't be blank"}
  validates :password, length: {minimum: 6, message: "Password must be at least 6 characters long"}
  validate :matching_passwords
  validates :email, presence: {message: "Email can't be blank"}
  validates :email, uniqueness: {message: "That email has already been taken"}
  
  def is_password?(password)
    BCrypt::Password.new(self.password_digest).is_password?(password)
  end
  
  def self.find_by_credentials(email, password)
    user = find_by_email(email)
    if user.nil?
      nil
    else
      user.is_password?(password) ? user : nil
    end
  end
  
  def reset_session_token!
    self.session_token = SecureRandom::urlsafe_base64
    self.save!
  end
  
  def full_name
    "#{self.fname} #{self.lname}"
  end
  
  def password=(password)
    @password = password
    if(@password) && !@password.empty?
      self.password_digest = BCrypt::Password.create(password)
    end
  end
  
  def password_confirmation=(password)
    @password_confirmation = password
  end
  
  def matching_passwords
    if self.password && !self.password.empty? && self.password != self.password_confirmation
      errors[:password] << "Passwords must match"
    end
  end
  
  def ensure_session_token
    self.session_token ||= SecureRandom::urlsafe_base64
  end
  
end
