class WelcomeController < LoggedOutController
  def index
    @include_google_analytics = true
    @include_thirdpartytag_dotcom = true
    @include_segment = true
  end
end