module TagsafeEmail
  class NewTagVersion < Base
    self.sendgrid_template_id = :'d-588eaf33c727495b8e64c6113d64449c'
    self.from_email = :'notifications@tagsafe.io'

    def initialize(user, tag_version)
      @to_email = user.email
      @template_variables = {
        tag_name: tag_version.tag.try_friendly_name,
        tag_url: tag_version.tag.url_based_on_preferences,
        site_url: tag_version.tag.domain.url,
        tag_version_tagsafe_url: mail_safe_url("/tags/#{tag_version.tag.uid}")
      }
    end
  end
end