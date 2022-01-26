class TakePageScreenshotJob < ApplicationJob
  def perform(page_url)
    response = LambdaModerator::PageUrlScreenshotter.new(page_url: page_url).send!
  end
end