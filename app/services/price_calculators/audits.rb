module PriceCalculators
  class Audits
    attr_accessor :audit

    def initialize(audit)
      @audit = audit
      @calculated_price = 0
    end

    def price
      @calculated_price += price_for_manual_test_runs + price_for_automated_test_runs
      @calculated_price += cumulative_price_for_performance_audit
    end

    def price_for(transaction_reason)
      {
        'automated_performance_audit' => price_for_automated_performance_audit,
        'automated_test_run' => price_for_automated_test_runs,
        'manual_performance_audit' => price_for_manual_performance_audit,
        'manual_test_run' => price_for_manual_test_runs,
        'performance_audit_recording' => price_for_puppeteer_recording,
        'performance_audit_filmstrip' => price_for_speed_index_filmstrip,
        'performance_audit_resources_waterfall' => price_for_resource_waterfall
      }[transaction_reason]
    end

    def cumulative_price_for_performance_audit
      # return 0 if audit.performance_audit_failed?
      price_for_automated_performance_audit + 
        price_for_manual_performance_audit +
        price_for_resource_waterfall + 
        price_for_puppeteer_recording + 
        price_for_speed_index_filmstrip
    end

    private

    # def price_for_performance_audit
    #   return 0 if free_of_charge?
    #   if !audit.include_performance_audit then 0
    #   elsif audit.execution_reason.manual? then feature_prices.manual_performance_audit_price
    #   elsif audit.execution_reason.automated? then feature_prices.automated_performance_audit_price
    #   else
    #     raise "Dont know how to calculate performance audit price for Audit #{audit.uid} with execution reason type of #{audit.execution_reason.name}."
    #   end
    # end

    # def price_for_test_runs
    #   return 0 if free_of_charge?
    #   if !audit.include_functional_tests then 0
    #   elsif audit.execution_reason.manual? then feature_prices.manual_test_run_price * audit.num_functional_tests_to_run
    #   elsif audit.execution_reason.automated? then feature_prices.automated_test_run_price * audit.num_functional_tests_to_run
    #   else
    #     raise "Dont know how to calculate test run price for Audit #{audit.uid} with execution reason type of #{audit.execution_reason.name}."
    #   end
    # end

    def price_for_automated_performance_audit
      @price_for_automated_performance_audit ||= begin
        return 0 if free_of_charge? || !audit.include_performance_audit || audit.execution_reason.manual?
        feature_prices.automated_performance_audit_price
      end
    end

    def price_for_automated_test_runs
      @price_for_automated_test_runs ||= begin
        return 0 if free_of_charge? || !audit.include_functional_tests || audit.execution_reason.manual?
        feature_prices.automated_test_run_price * audit.num_functional_tests_to_run
      end
    end

    def price_for_manual_performance_audit
      @price_for_manual_performance_audit ||= begin
        return 0 if free_of_charge? || !audit.include_performance_audit || !audit.execution_reason.manual?
        feature_prices.manual_performance_audit_price
      end
    end

    def price_for_manual_test_runs
      @price_for_manual_test_runs ||= begin
        return 0 if free_of_charge? || !audit.include_functional_tests || !audit.execution_reason.manual?
        feature_prices.manual_test_run_price * audit.num_functional_tests_to_run
      end
    end

    def price_for_resource_waterfall
      @price_for_resource_waterfall ||= begin
        return 0 if free_of_charge?
        return 0 unless audit.include_page_load_resources
        feature_prices.resource_waterfall_price
      end
    end

    def price_for_puppeteer_recording
      @price_for_puppeteer_recording ||= begin
        return 0 if free_of_charge?
        return 0 unless audit.performance_audit_configuration.enable_screen_recording
        feature_prices.puppeteer_recording_price
      end
    end

    def price_for_speed_index_filmstrip
      @price_for_speed_index_filmstrip ||= begin
        return 0 if free_of_charge?
        return 0 unless audit.performance_audit_configuration.include_filmstrip_frames
        feature_prices.speed_index_filmstrip_price
      end
    end

    def free_of_charge?
      audit.execution_reason.tagsafe_provided? || (audit.execution_reason.manual? && feature_prices.manual_performance_audit_price.zero?)
    end

    def domain_wallet
      @domain_wallet ||= audit.domain.credit_wallet_for_current_month_and_year
    end

    def feature_prices
      @feature_prices ||= audit.domain.feature_prices_in_credits
    end
  end
end