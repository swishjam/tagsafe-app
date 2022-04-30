module TagsafeEmail
  class NewTag < Base
    self.sendgrid_template_id = :'d-49852daabc35489b95bb4d45e93ff10c'
    self.from_email = :'notifications@tagsafe.io'

    def initialize(user, tag)
      @to_email = user.email
      @template_variables = {
        tag_url: tag.full_url,
        tag_name: tag.try_friendly_name,
        tag_image_url: tag.try_image_url,
        domain_url: tag.domain.url,
        tag_tagsafe_url: mail_safe_url("/tags/#{tag.id}")
      }
    end
  end
end