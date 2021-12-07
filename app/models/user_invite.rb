class UserInvite < ApplicationRecord  
  belongs_to :organization
  belongs_to :invited_by_user, class_name: 'User'

  scope :redeemable, -> { where('redeemed_at = ? AND expires_at < ?', nil, DateTime.now) }
  scope :redeemed, -> { where.not(redeemed_at: nil) }
  scope :not_redeemed, -> { where(redeemed_at: nil) }
  scope :expired, -> { where('expires_at >= ?', DateTime.now) }
  scope :not_expired, -> { where('expires_at < ?', DateTime.now) }

  after_create :send_invite!

  validate :user_doesnt_exist
  validate :user_doesnt_have_pending_invite

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

  def redeemable?
    redeemed_at.nil? && !expired?
  end

  def expired?
    expires_at < DateTime.now
  end
  
  def send_invite!
    TagSafeMailer.send_user_invite_email(self)
  end

  private

  def user_doesnt_exist
    if organization.users.find_by(email: email)
      errors.add(:base, "User already belongs to #{organization.name}.")
    end
  end

  def user_doesnt_have_pending_invite
    if organization.user_invites.redeemable.find_by(email: email)
      errors.add(:base, "User already has a pending invite.")
    end
  end
end