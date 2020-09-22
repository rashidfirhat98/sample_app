class User < ApplicationRecord
  attr_accessor :remember_token, :activation_token

  validates :name, presence: true,
    length: {maximum: Settings.validate.name.max_length}

  validates :email, presence: true,
    length: {maximum: Settings.validate.email.max_length},
    format: {with: Settings.validate.email.regex},
    uniqueness: true

  validates :password, presence: true,
    length: {minimum: Settings.validate.password.min_length},
    allow_nil: true

  has_secure_password

  before_save :downcase_email
  before_create :create_activation_digest

  class << self
    def new_token
      SecureRandom.urlsafe_base64
    end

    def digest string
      cost = if ActiveModel::SecurePassword.min_cost
              BCrypt::Engine::MIN_COST
            else
              BCrypt::Engine.cost
            end
      BCrypt::Password.create string, cost: cost
    end
  end

  def remember
    self.remember_token = User.new_token
    update_attribute :remember_digest, User.digest(remember_token)
  end

  def forget
    update_attribute :remember_digest, nil
  end

  def authenticated? remember_token
    return false unless remember_digest
    BCrypt::Password.new remember_digest.is_password? remember_token
  end

  def authenticated? attribute, token
    digest = send "#{attribute}_digest"
    return false unless digest

    BCrypt::Password.new(digest).is_password? token
  end

  def activate
    update activated: true, activated_at: Time.zone.now
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  private

  def downcase_email
    self.email.downcase!
  end

  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest activation_token
  end
end
