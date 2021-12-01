class WelcomeController < LoggedOutController
  def index
    @include_google_analytics = true
    @include_thirdpartytag_dotcom = true
    @include_segment = true
  end

  def learn_more
    TagSafeMailer.generic_email(
      to: 'collin@tagsafe.io', 
      subject: 'User interested', 
      body: "#{params[:email]} is interested in TagSafe."
    )
    head :ok
  end
end