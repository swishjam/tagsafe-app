module TagsafeEmail
  class TagRemovedAlert < Base
    self.sendgrid_template_id = :''
    self.from_email = :'alerts@tagsafe.io'

    def initialize(user:, alert_configuration:, initiating_record:, triggered_alert:)
      @to_email = user.email
      tag = initiating_record
      @template_variables = {
        tag_friendly_name: tag.try_friendly_name,
        tag_url: tag.url_based_on_preferences,
        container_name: tag.container.name,
        tag_details_url: mail_safe_url("/tags/#{tag.uid}?_container_uid=#{tag_version.tag.container.uid}")
      }
    end
  end
end