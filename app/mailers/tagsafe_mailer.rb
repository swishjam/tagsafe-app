class TagsafeMailer < SendgridTemplateMailer
  class << self
    def generic_email(to:, subject:, body:, from: 'notifications@tagsafe.io')
      send!(
        to: to,
        from: from,
        template_name: :generic,
        template_variables: {
          subject: subject,
          body: body
        }
      )
    end

    def send_welcome_email(user)
      send!(
        to: user.email, 
        from: 'collin@tagsafe.io', 
        template_name: :welcome, 
        template_variables: { 
          friendly_name: user.first_name 
        }
      )
    end
  
    def send_user_invite_email(user_invite)
      send!(
        to: user_invite.email,
        from: 'notifications@tagsafe.io',
        template_name: :user_invite,
        template_variables: {
          domain_url: user_invite.domain.url,
          accept_invite_url: mail_safe_url("/user_invites/#{user_invite.token}/accept"),
          inviter_name: user_invite.invited_by_user.full_name
        }
      )
    end
  
    def send_new_tag_version_email(user, tag_version)
      send!(
        to: user.email,
        from: 'notifications@tagsafe.io',
        template_name: :new_tag_version,
        template_variables: {
          tag_name: tag_version.tag.try_friendly_name,
          tag_url: tag_version.tag.url_based_on_preferences,
          site_url: tag_version.tag.domain.url,
          tag_version_tagsafe_url: mail_safe_url("/tags/#{tag_version.tag.id}")
        }
      )
    end
  
    def send_audit_completed_email(audit, user)
      template_variables = {
        tag_name: audit.tag.try_friendly_name,
        tagsafe_score: audit.preferred_delta_performance_audit.tagsafe_score
      }
      change_in_score = audit.preferred_delta_performance_audit.change_in_metric(:tagsafe_score)
      if change_in_score
        template_variables[:change_in_score_description] = <<~DESCRIPTION
          This is a#{change_in_score.positive? ? 'n increase' : ' decrease'} from the previous Tagsafe score of #{audit.preferred_delta_performance_audit.previous_metric_result(:tagsafe_score)}
        DESCRIPTION
      end
      send!(
        to: user.email,
        from: 'notifications@tagsafe.io',
        template_name: :audit_completed,
        template_variables: template_variables
      )
    end
  
    def send_new_tag_detected_email(user, tag)
      send!(
        to: user.email, 
        from: 'notifications@tagsafe.io', 
        template_name: :new_tag, 
        template_variables: {
          new_tag_url: tag.full_url,
          new_tag_name: tag.try_friendly_name,
          new_tag_image_url: tag.try_image_url,
          domain_url: tag.domain.url,
          new_tag_tagsafe_url: mail_safe_url("/tags/#{tag.id}")
        }
      )
    end

    private

    def mail_safe_url(path)
      "#{ENV['CURRENT_HOST'] || 'https://www.tagsafe.io'}#{path}"
    end
  end
end