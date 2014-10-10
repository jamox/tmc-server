require 'securerandom'

# Each user may have 0..1 account activation keys.
class AccountConfirmationKey < ActiveRecord::Base
  belongs_to :user
  validates :user_id, :presence => true, :uniqueness => true
  validates :code, :uniqueness => true  # this going wrong should be extremely unlikely

  before_create :randomize_code

  def self.generate_for(user)
    old_key = user.account_confirmation_key
    old_key.destroy if old_key

    key = self.create!(:user => user)
    user.account_confirmation_key = key
    key
  end

  def expired?
    self.created_at < Time.now - 24.hours
  end

private
  def randomize_code
    self.code = SecureRandom.hex(32)
  end
end
