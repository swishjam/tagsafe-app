class FeatureGateKeeper
  def initialize(domain)
    @domain = domain
  end

  def can_run_audit?
    defined?(@can_run_audit) ? @can_run_audit : begin
      return @can_run_audit = true unless domains_subscription_option.basic?
      @can_run_audit = num_audits_remaining < 50
    end
  end

  def num_audits_remaining
    return Float::Infinity unless domains_subscription_option.basic?
    @num_audits_remaining ||= @domain.num_audits_remaining_this_month
  end

  def can_run_functional_tests?
    !domains_subscription_option.basic?
  end

  def can_include_performance_audit_screen_recording?
    @can_include_performance_audit_screen_recording ||= domains_subscription_option.pro? && !@domain.subscription_plan.delinquent?
  end

  def can_view_tag_version_git_diff?
    @can_view_tag_version_git_diff ||= domains_subscription_option.pro? && !@domain.subscription_plan.delinquent?
  end

  def can_include_page_load_resources_in_audit?
    @can_include_page_load_resources_in_audit ||= domains_subscription_option.pro? && !@domain.subscription_plan.delinquent?
  end

  private

  def domains_subscription_option
    @domains_subscription_option ||= @domain.selected_subscription_option
  end
end