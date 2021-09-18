module Api
  class GeppettoReceiverController < BaseController
    def url_crawl_complete
      binding.pry
      head :ok
      # receive!('UrlCrawled',
      #   url_crawl_id: formatted_lambda_event_response&.dig(:url_crawl_id),
      #   error_message: formatted_lambda_event_response&.dig(:error),
      #   initial_crawl: formatted_lambda_event_response&.dig(:initial_crawl),
      #   tag_urls: formatted_lambda_event_response&.dig(:tag_urls)
      # )
      # receive!('UrlCrawled',
      #   url_crawl_id: params[:url_crawl_id],
      #   error_message: params[:error],
      #   initial_crawl: params[:initial_crawl],
      #   tag_urls: params[:tag_urls]
      # )
    end

    def performance_audit_complete
      binding.pry
      receive!('IndividualPerformanceAuditCompleted',
        individual_performance_audit_id: formatted_lambda_event_response&.dig(:individual_performance_audit_id),
        results: JSON.parse(formatted_lambda_event_response&.dig(:results)&.to_json || '{}'),
        logs: formatted_lambda_event_response&.dig(:logs),
        error: formatted_lambda_event_response&.dig(:error)
      )
    end

    private

    def formatted_lambda_event_response
      params.dig(:detail, :responsePayload, :body)
      # params[:detail][:responsePayload][:body]
    end

    def receive!(class_string, data = {})
      check_api_token
      "GeppettoModerator::Receivers::#{class_string}".constantize.new(data).receive!
      head :ok
    end
  end
end