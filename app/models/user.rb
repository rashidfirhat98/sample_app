class User < ApplicationRecord
  validates :name, presence: true,
    length: {maximum: Settings.user.name.max_length}

  validates :email, presence: true,
    length: {maximum: Settings.user.email.max_length},
    format: {with: Settings.user.email.regex},
    uniqueness: true

  validates :password, presence: true,
    length: {minimum: Settings.user.password.min_length}

  has_secure_password

  before_save :downcase_email

  private

  def downcase_email
    email.downcase!
  end
end
