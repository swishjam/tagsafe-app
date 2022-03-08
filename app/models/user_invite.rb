class UserInvite < ApplicationRecord  
  belongs_to :domain
  belongs_to :invited_by_user, class_name: User.to_s

  scope :redeemable, -> { where('redeemed_at = ? AND expires_at < ?', nil, DateTime.now) }
  scope :redeemed, -> { where.not(redeemed_at: nil) }
  scope :not_redeemed, -> { where(redeemed_at: nil) }
  scope :expired, -> { where('expires_at >= ?', DateTime.now) }
  scope :not_expired, -> { where('expires_at < ?', DateTime.now) }

  after_create_commit :send_invite!
  after_create_commit :re_render_pending_invite_list

  validate :user_doesnt_exist
  validate :user_doesnt_have_pending_invite

  def self.invite!(email, domain, invited_by_user)
    create!(
      domain: domain,
      email: email,
      invited_by_user: invited_by_user,
      expires_at: DateTime.now + 1.day,
      token: SecureRandom.hex(12)
    )
  end

  def redeem!(new_user)
    new_user.domains << domain
    touch(:redeemed_at)
  end

  def redeemable?
    redeemed_at.nil? && !expired?
  end

  def expired?
    expires_at < DateTime.now
  end
  
  def send_invite!
    TagsafeMailer.send_user_invite_email(self)
  end

  def re_render_pending_invite_list
    broadcast_replace_to(
      "domain_#{domain.uid}_user_invites_stream",
      target: "domain_#{domain.uid}_pending_invites",
      partial: 'user_invites/index',
      locals: { 
        domain: domain,
        invite_list_type: :pending,
        user_invites: domain.user_invites.not_redeemed 
      }
    )
  end

  private

  def user_doesnt_exist
    if domain.users.find_by(email: email)
      errors.add(:base, "User already belongs to #{domain.url}.")
    end
  end

  def user_doesnt_have_pending_invite
    if domain.user_invites.redeemable.find_by(email: email)
      errors.add(:base, "User already has a pending invite.")
    end
  end
end