class WelcomeController < LoggedOutController
  def index
    @include_google_analytics = ENV['INCLUDE_GOOGLE_ANALYTICS_TAG_DEMO'] == 'true'
    @include_thirdpartytag_dotcom = ENV['INCLUDE_THIRDPARTYTAG_DOTCOM_TAG_DEMO'] == 'true'
    @include_segment = ENV['INCLUDE_SEGMENT_TAG_DEMO'] == 'true'
    @include_new_relic = ENV['INCLUDE_NEW_RELIC_TAG_DEMO'] == 'true'
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