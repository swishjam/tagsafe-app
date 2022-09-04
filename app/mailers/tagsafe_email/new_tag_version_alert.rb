module TagsafeEmail
  class NewTagVersionAlert < Base
    self.sendgrid_template_id = :'d-588eaf33c727495b8e64c6113d64449c'
    self.from_email = :'alerts@tagsafe.io'

    def initialize(user:, alert_configuration:, initiating_record:, triggered_alert:)
      @to_email = user.email
      tag_version = initiating_record
      @template_variables = {
        tag_friendly_name: tag_version.tag.try_friendly_name,
        tag_url: tag_version.tag.url_based_on_preferences,
        domain_url: tag_version.tag.domain.url,
        audit_url: mail_safe_url("/tags/#{tag_version.tag.uid}/tag_versions/#{tag_version.uid}/audit_redirect?_domain_uid=#{tag_version.tag.domain.uid}")
      }
    end
  end
end