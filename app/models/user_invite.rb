class UserInvite < ApplicationRecord  
  belongs_to :container
  belongs_to :invited_by_user, class_name: User.to_s

  scope :pending, -> { where(redeemed_at: nil) }
  scope :redeemable, -> { where('redeemed_at = ? AND expires_at < ?', nil, DateTime.now) }
  scope :redeemed, -> { where.not(redeemed_at: nil) }
  scope :not_redeemed, -> { where(redeemed_at: nil) }
  scope :expired, -> { where('expires_at >= ?', DateTime.now) }
  scope :not_expired, -> { where('expires_at < ?', DateTime.now) }

  after_create_commit :send_invite!
  after_create_commit :re_render_pending_invite_list

  validate :user_doesnt_exist
  validate :user_doesnt_have_pending_invite

  def self.invite!(email, container, invited_by_user)
    create(
      container: container,
      email: email,
      invited_by_user: invited_by_user,
      expires_at: DateTime.now + 1.day,
      token: SecureRandom.hex(12)
    )
  end

  def redeem!(new_user)
    new_user.containers << container
    touch(:redeemed_at)
  end

  def status
    redeemed? ? 'accepted' : expired? ? 'expired' : 'pending'
  end

  def redeemed?
    redeemed_at.present?
  end

  def redeemable?
    redeemed_at.nil? && !expired?
  end

  def expired?
    expires_at < DateTime.now
  end
  
  def send_invite!
    TagsafeEmail::Invitation.new(self).send!
  end

  def re_render_pending_invite_list
    broadcast_replace_to(
      "container_#{container.uid}_user_invites_stream",
      target: "container_#{container.uid}_pending_invites",
      partial: 'user_invites/index',
      locals: { 
        container: container,
        status: :pending,
        user_invites: container.user_invites.pending 
      }
    )
  end

  private

  def user_doesnt_exist
    if container.users.find_by(email: email)
      errors.add(:base, "A user with the email of '#{email}' already has access to your #{container.name} container.")
    end
  end

  def user_doesnt_have_pending_invite
    if container.user_invites.redeemable.find_by(email: email)
      errors.add(:base, "User already has a pending invite.")
    end
  end
end