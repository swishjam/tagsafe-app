class ScriptChangeMailer < ApplicationMailer
  default from: 'collinschneider3@gmail.com'

  def send_script_changed_email(user, script_subscriber, script_change)
    @user = user
    @script_change = script_change
    @script_subscriber = script_subscriber
    @script = script_change.script
    mail(to: @user.email, subject: "#{@script.url} changed.")
  end
end