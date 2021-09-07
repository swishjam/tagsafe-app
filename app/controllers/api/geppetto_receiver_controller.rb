module Api
  class GeppettoReceiverController < BaseController
    def url_crawl_complete
      receive!('UrlCrawled',
        domain_id: params[:domain_id],
        url_crawl_id: params[:url_crawl_id],
        error_message: params[:error],
        initial_scan: params[:initial_scan],
        tag_urls: JSON.parse(params[:tag_urls])
      )
    end

    def performance_audit_complete
      receive!('PerformanceAuditCompleted',
        error: params[:error], 
        audit_id: params[:audit_id],
        num_attempts: params[:num_attempts].to_i,
        results_with_tag: JSON.parse(params[:results_with_tag]),
        results_without_tag: JSON.parse(params[:results_without_tag])
      )
    end

    private

    def receive!(class_string, data = {})
      check_api_token
      GeppettoModerator::Receiver.new(class_string, data).receive!
      head :ok
    end
  end
end