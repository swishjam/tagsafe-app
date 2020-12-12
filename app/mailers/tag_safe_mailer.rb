class TagSafeMailer < ApplicationMailer
  def send_user_invite_email(user_invite)
    @invited_by_user = user_invite.invited_by_user
    @organization = user_invite.organization
    @token = user_invite.token
    @accept_invite_url = "#{ENV['HOST']}/invite/#{@token}/accept"
    mail(to: user_invite.email, from: 'hello@tagsafe.io', subject: "You've been invited to TagSafe.")
  end

  def send_script_changed_email(user, script_subscriber, script_change)
    @user = user
    @script_change = script_change
    @script_subscriber = script_subscriber
    @script = script_change.script
    mail(to: @user.email, from: 'changes@tagsafe.io', subject: "#{@script_subscriber.try_friendly_name} changed.")
  end

  def send_audit_completed_email(audit, user)
    @audit = audit
    @script_subscriber = @audit.script_subscriber
    @previous_audit = @script_subscriber.primary_audit_by_script_change(@script_subscriber.script.most_recent_change&.previous_change)
    mail(to: user.email, from: 'changes@tagsafe.io', subject: "Audit for #{@script_subscriber.try_friendly_name} completed.")
  end

  def send_new_tag_detected_email(user, script_subscriber)
    @user = user
    @script_subscriber = script_subscriber
    @script = script_subscriber.script
    @domain = script_subscriber.domain
    mail(to: user.email, from: 'changes@tagsafe.io', subject: "New tag detected on #{script_subscriber.domain.url}.")
  end
end