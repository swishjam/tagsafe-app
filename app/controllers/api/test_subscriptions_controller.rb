module Api
  class TestSubscriptionsController < Api::BaseController
    def toggle
      ts = TestSubscriber.find(params[:id])
      ts.update(active: !ts.active)
      render json: { 
        success: true,
        message: "#{ts.script.url} is no longer subscribed to test #{ts.test.title}"
      }
    end
  end
end