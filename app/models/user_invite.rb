class UserInvite < ApplicationRecord  
  belongs_to :container
  belongs_to :invited_by_user, class_name: User.to_s
  belongs_to :redeemed_by_user, class_name: User.to_s, optional: true

  scope :pending, -> { where(redeemed_at: nil) }
  scope :redeemable, -> { where('redeemed_at = ? AND expires_at < ?', nil, Time.current) }
  scope :redeemed, -> { where.not(redeemed_at: nil) }
  scope :not_redeemed, -> { where(redeemed_at: nil) }
  scope :expired, -> { where('expires_at >= ?', Time.current) }
  scope :not_expired, -> { where('expires_at < ?', Time.current) }

  after_create_commit :send_invite_or_add_user_to_container!
  after_create_commit :re_render_pending_invite_list

  validate :user_doesnt_exist, on: :create
  validate :user_doesnt_have_pending_invite, on: :create

  def self.invite!(email, container, invited_by_user)
    create(
      container: container,
      email: email,
      invited_by_user: invited_by_user,
      expires_at: 7.days.from_now,
      token: SecureRandom.hex(12)
    )
  end

  def redeem!(new_user)
    new_user.containers << container
    update!(redeemed_by_user: new_user, redeemed_at: Time.current)
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

  private
  
  def send_invite_or_add_user_to_container!
    existing_user = User.find_by(email: email)
    if existing_user
      # TODO: need an email notification
      redeem!(existing_user)
    else
      TagsafeEmail::Invitation.new(self).send!
    end
  end

  def re_render_pending_invite_list
    broadcast_replace_to(
      "container_#{container.uid}_user_invites_stream",
      target: "container_#{container.uid}_pending_invites",
      partial: 'user_invites/index',
      locals: { 
        container: container,
        status: :pending,
        pending_user_invites: container.user_invites.pending 
      }
    )
  end

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