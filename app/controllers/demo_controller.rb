class DemoController < ApplicationController
  def index
    @hide_navigation = true
    @include_thirdpartytag_dotcom = true
    @include_google_analytics = true
    @include_segment = true
  end
end