module TagsafeEmail
  class FunctionalTestSuiteFailed < Base
    self.sendgrid_template_id = :''
    self.from_email = :'alerts@tagsafe.io'

    def initialize(user:, alert_configuration:, initiating_record:, triggered_alert:)
      @to_email = user.email
      audit = initiating_record
      @template_variables = {
        tag_friendly_name: tag.try_friendly_name,
        tag_url: tag.url_based_on_preferences,
        domain_url: tag.domain.url_hostname,
        tag_details_url: mail_safe_url("/tags/#{tag.uid}?_domain_uid=#{tag_version.tag.domain.uid}")
      }
    end
  end
end