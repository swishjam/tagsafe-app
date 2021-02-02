class UserInvite < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by_user, class_name: 'User'

  after_create :send_invite!

  validate :user_doesnt_exist

  def self.invite!(email, organization, invited_by_user)
    create!(
      organization: organization,
      email: email,
      invited_by_user: invited_by_user,
      expires_at: DateTime.now + 1.day,
      token: SecureRandom.hex(12)
    )
  end

  def redeem!(new_user)
    new_user.organizations << organization
    touch(:redeemed_at)
  end

  def reedemable?
    redeemed_at.nil? && !expired?
  end

  def expired?
    expires_at < DateTime.now
  end
  
  def send_invite!
    TagSafeMailer.send_user_invite_email(self).deliver
  end

  private

  def user_doesnt_exist
    if User.find_by(email: email)
      # errors.add(:base, "User already exists in the TagSafe system.")
    end
  end
end