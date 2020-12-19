module Api
  class GeppettoReceiverController < BaseController
    before_action :check_api_token

    def domain_scan_complete
      receive!('DomainScanned',
        domain_id: params[:domain_id],
        domain_scan_id: params[:domain_scan_id],
        error_message: params[:error],
        scripts: JSON.parse(params[:scripts])
      )
    end

    def performance_audit_complete
      receive!('PerformanceAuditCompleted',
        error: params[:error], 
        with_tag_logs: params[:with_tag_logs],
        without_tag_logs: params[:without_tag_logs],
        audit_id: params[:audit_id],
        num_attempts: params[:num_attempts].to_i,
        results_with_tag: JSON.parse(params[:results_with_tag] || '[]'), 
        results_without_tag: JSON.parse(params[:results_without_tag] || '[]')
      )
    end

    def test_group_complete
      receive!('TestGroupCompleted',
        test_group_run_id: params[:test_group_run_id],
        audit_id: params[:audit_id],
        test_results_with_current_tag: JSON.parse(params[:test_results_with_current_tag]),
        test_results_with_previous_tag: JSON.parse(params[:test_results_with_previous_tag]),
        test_results_without_tag: JSON.parse(params[:test_results_without_tag])
      )
    end

    def standalone_test_complete
      receive!('StandaloneTestCompleted',
        test_id: params[:test_id],
        domain_id: params[:domain_id],
        test_result: JSON.parse(params[:results])
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