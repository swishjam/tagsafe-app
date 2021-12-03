class WelcomeController < LoggedOutController
  def index
    @include_google_analytics_tag = ENV['INCLUDE_GOOGLE_ANALYTICS_TAG_DEMO'] == 'true'
    @include_thirdpartytag_dotcom_tag = ENV['INCLUDE_THIRDPARTYTAG_DOTCOM_TAG_DEMO'] == 'true'
    @include_segment_tag = ENV['INCLUDE_SEGMENT_TAG_DEMO'] == 'true'
    @include_new_relic_tag = ENV['INCLUDE_NEW_RELIC_TAG_DEMO'] == 'true'
    @include_amplitude_tag = ENV['INCLUDE_AMPLITUDE_TAG_DEMO'] == 'true'
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