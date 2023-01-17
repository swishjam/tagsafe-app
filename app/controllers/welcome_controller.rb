class WelcomeController < LoggedOutController
  def index
  end

  def contact
    body = <<~BODY
      Incoming 'Contact Us' Email: \n
      Provided Email: #{params[:email]}\n
      Provided Company: #{params[:company]}\n
      Provided Name: #{params[:name]}\n\n\n
      Reason: #{params[:reason]}\n\n\n
      Logged in User UID: #{current_user&.uid}\n\n\n
      Logged in Container UID: #{@container&.uid}\n\n\n
      Message:\n#{params[:message]}
    BODY
    TagsafeEmail::Generic.new(
      to_email: 'contact@tagsafe.io',
      subject: "Contact Us - #{params[:reason]}",
      body: body
    ).send!
    render turbo_stream: turbo_stream.replace(
      'contact_form',
      locals: { success_message: 'Thanks for reaching out, we\'ll be in touch shortly!' },
      partial: 'welcome/contact_form'
    )
  end
end