class ScriptChangeMailer < ApplicationMailer
  default from: 'collinschneider3@gmail.com'

  def send_script_changed_email(user, script_change)
    @user = user
    @script_change = script_change
    @monitored_script = script_change.monitored_script
    mail(to: @user.email, subject: "#{@monitored_script.url} changed.")
  end
end