class WelcomeController < LoggedOutController
  def index
    @include_google_analytics_tag = ENV['INCLUDE_GOOGLE_ANALYTICS_TAG_DEMO'] == 'true'
    @include_thirdpartytag_dotcom_tag = ENV['INCLUDE_THIRDPARTYTAG_DOTCOM_TAG_DEMO'] == 'true'
    @include_segment_tag = ENV['INCLUDE_SEGMENT_TAG_DEMO'] == 'true'
    @include_new_relic_tag = ENV['INCLUDE_NEW_RELIC_TAG_DEMO'] == 'true'
    @include_amplitude_tag = ENV['INCLUDE_AMPLITUDE_TAG_DEMO'] == 'true'
  end

  def contact
    body = <<~BODY
      Incoming 'Contact Us' Email: \n
      Provided Email: #{params[:email]}\n
      Provided Company: #{params[:company]}\n
      Provided Name: #{params[:name]}\n\n\n
      Reason: #{params[:reason]}\n\n\n
      Logged in User UID: #{current_user&.uid}\n\n\n
      Logged in Domain UID: #{current_domain&.uid}\n\n\n
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