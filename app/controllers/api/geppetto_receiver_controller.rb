module Api
  class GeppettoReceiverController < BaseController
    def url_crawl_complete
      receive!('UrlCrawled',
        url_crawl_id: params[:url_crawl_id],
        error_message: params[:error],
        initial_crawl: params[:initial_crawl],
        tag_urls: params[:tag_urls]
      )
    end

    def performance_audit_complete
      receive!('IndividualPerformanceAuditCompleted',
        individual_performance_audit_id: params[:individual_performance_audit_id],
        results: JSON.parse(params[:results]&.to_json || '{}'),
        logs: params[:logs],
        error: params[:error]
      )
    end

    private

    def receive!(class_string, data = {})
      check_api_token
      "GeppettoModerator::Receivers::#{class_string}".constantize.new(data).receive!
      head :ok
    end
  end
end