module Api
  class GeppettoReceiverController < BaseController
    before_action :check_api_token

    def domain_scan_complete
      receive!('DomainScanned',
        domain_id: params[:domain_id],
        scripts: JSON.parse(params[:scripts]),
        error: params[:error]
      )
    end

    def performance_audit_complete
      receive!('PerformanceAuditCompleted',
        error: params[:error], 
        results_with_tag: JSON.parse(params[:results_with_tag] || '[]'), 
        results_without_tag: JSON.parse(params[:results_without_tag] || '[]'), 
        with_tag_logs: params[:with_tag_logs],
        without_tag_logs: params[:without_tag_logs],
        audit_id: params[:audit_id],
        num_attempts: params[:num_attempts].to_i
      )
    end

    def test_group_complete
      receive!('TestGroupCompleted',
        test_results_with_current_tag: JSON.parse(params[:test_results_with_current_tag]),
        test_results_with_previous_tag: JSON.parse(params[:test_results_with_previous_tag]),
        test_results_without_tag: JSON.parse(params[:test_results_without_tag]),
        test_group_run_id: params[:test_group_run_id],
        audit_id: params[:audit_id]
      )
    end

    def standalone_test_complete
      receive!('StandaloneTestCompleted',
        test_result: JSON.parse(params[:results]),
        test_id: params[:test_id],
        domain_id: params[:domain_id]
      )
    end

    private

    def receive!(class_string, data = {})
      check_api_token
      GeppettoModerator::Receiver.new(class_string, data).receive!
      head :ok
    end
    
    def check_api_token
      # Rails.logger.info "Bypassing API token check for now."
    end
  end
end