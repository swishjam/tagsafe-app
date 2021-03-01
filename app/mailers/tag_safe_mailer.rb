require 'sendgrid-ruby'
class TagSafeMailer < SendgridTemplateMailer
  include SendGrid
  class << self
    def send_welcome_email(user)
      @to_email = user.email
      @from_email = 'collin@tagsafe.io'
      @variable_json = { friendly_name: "#{user.first_name}" }.to_json
      @template_name = :welcome
      send!
    end
  
    def send_user_invite_email(user_invite)
      @to_email = user_invite.email
      @from_email = "hello@tagsafe.io"
      @template_name = :user_invite
      @variable_json = {
        organization_name: user_invite.organization.name,
        invitation_url: "#{ENV['CURRENT_HOST']}/invite/#{user_invite.token}/accept",
        invited_by_user: user_invite.invited_by_user
      }
      send!
    end
  
    def send_script_changed_email(user, script_subscriber, script_change)
      # @user = user
      # @script_change = script_change
      # @script_subscriber = script_subscriber
      # @script = script_change.script
      @to_email = user.email
      @from_email = 'changes@tagsafe.io'
      @template_name = :tag_changed
      @variable_json = {
        tag_name: script_subscriber.try_friendly_name
      }.to_json
      send!
      # mail(to: @user.email, from: 'changes@tagsafe.io', subject: "#{@script_subscriber.try_friendly_name} changed.")
    end
  
    def send_audit_completed_email(audit, user)
      # @audit = audit
      # @script_subscriber = @audit.script_subscriber
      # @previous_audit = @script_subscriber.primary_audit_by_script_change(@script_subscriber.script.most_recent_change&.previous_change)
      @to_email = user.email
      @from_email = 'changes@tagsafe.io'
      @template_name = :audit_completed
      send!
      # mail(to: user.email, from: 'changes@tagsafe.io', subject: "Audit for #{@script_subscriber.try_friendly_name} completed.")
    end
  
    def send_new_tag_detected_email(user, script_subscriber)
      # @user = user
      # @script_subscriber = script_subscriber
      # @script = script_subscriber.script
      # @domain = script_subscriber.domain
      @to_email = user.email
      @from_email = 'changes@tagsafe.io'
      @template_name = :new_tag
      send!
      # mail(to: user.email, from: 'changes@tagsafe.io', subject: "New tag detected on #{@domain.url}.")
    end
  end
end