class TagSafeMailer < SendgridTemplateMailer
  class << self
    def generic_email(to:, subject:, body:, from: 'notifications@tagsafe.io')
      @to_email = to
      @template_name = :generic
      @from_email = from
      @variable_json = { 
        subject: subject,
        body: body
      }
      send!
    end

    def send_welcome_email(user)
      @to_email = user.email
      @from_email = 'collin@tagsafe.io'
      @variable_json = { friendly_name: "#{user.first_name}" }
      @template_name = :welcome
      send!
    end
  
    def send_user_invite_email(user_invite)
      @to_email = user_invite.email
      @from_email = "notifications@tagsafe.io"
      @template_name = :user_invite
      @variable_json = {
        domain_url: user_invite.domain.url,
        accept_invite_url: mail_safe_url("/user_invites/#{user_invite.token}/accept"),
        inviter_name: user_invite.invited_by_user.full_name
      }
      send!
    end
  
    def send_new_tag_version_email(user, tag, tag_version)
      @to_email = user.email
      @from_email = 'notifications@tagsafe.io'
      @template_name = :new_tag_version
      @variable_json = { 
        tag_name: tag.try_friendly_name,
        site_url: tag.domain.url,
        tag_version_tagsafe_url: mail_safe_url("/tags/#{tag.id}")
      }
      send!
    end
  
    def send_audit_completed_email(audit, user)
      @to_email = user.email
      @from_email = 'notifications@tagsafe.io'
      @template_name = :audit_completed
      change_in_score = audit.preferred_delta_performance_audit.change_in_metric(:tagsafe_score)
      @variable_json = {
        tag_name: audit.tag.try_friendly_name,
        tagsafe_score: audit.preferred_delta_performance_audit.tagsafe_score
      }
      if change_in_score
        @variable_json[:change_in_score_description] = <<~DESCRIPTION
          This is a#{change_in_score.positive? ? 'n increase' : ' decrease'} from the previous TagSafe score of #{audit.preferred_delta_performance_audit.previous_metric_result(:tagsafe_score)}
        DESCRIPTION
      end
      send!
    end
  
    def send_new_tag_detected_email(user, tag)
      @to_email = user.email
      @from_email = 'notifications@tagsafe.io'
      @template_name = :new_tag
      @variable_json = {
        new_tag_url: tag.full_url,
        site_url: tag.domain.url,
        new_tag_tagsafe_url: mail_safe_url("/tags/#{tag.id}/edit")
      }
      send!
    end

    private

    def mail_safe_url(path)
      "#{ENV['CURRENT_HOST'] || 'https://www.tagsafe.io'}#{path}"
    end
  end
end