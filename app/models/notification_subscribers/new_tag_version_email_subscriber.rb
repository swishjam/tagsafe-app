class NewTagVersionEmailSubscriber < EmailNotificationSubscriber
  def self.friendly_name
    'script changed'
  end

  def send_email!(tag_version)
    TagsafeMailer.send_new_tag_version_email(user, tag, tag_version)
  end
end