module TagsafeEmail
  class NewTag < Base
    self.sendgrid_template_id = :'d-49852daabc35489b95bb4d45e93ff10c'
    self.from_email = :'notifications@tagsafe.io'

    def initialize(user, tag)
      @to_email = user.email
      @template_variables = {
        user_first_name: user.first_name,
        tag_url: tag.url_based_on_preferences,
        tag_friendly_name: tag.try_friendly_name,
        tag_image_url: tag.image_url,
        container_name: tag.container_name,
        edit_tag_url: mail_safe_url("/tags/#{tag.uid}/edit?_container_uid=#{tag.container.uid}")
      }
    end
  end
end