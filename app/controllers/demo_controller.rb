class DemoController < ApplicationController
  def index
    @hide_navigation = true
    @include_thirdpartytag_dotcom = true
  end
end