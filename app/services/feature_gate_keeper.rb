class FeatureGateKeeper
  def initialize(domain)
    @domain = domain
  end

  def can_run_audit?
    true
  end

  def can_run_scheduled_audits?
    return @can_run_scheduled_audits if defined?(@can_run_scheduled_audits)
    domains_subscription_option.basic?
  end

  def can_run_functional_tests?
    # !domains_subscription_option.basic?
    true
  end

  def can_include_performance_audit_screen_recording?
    # @can_include_performance_audit_screen_recording ||= domains_subscription_option.pro? && !@domain.current_subscription_plan.delinquent?
    true
  end

  def can_view_tag_version_git_diff?
    # @can_view_tag_version_git_diff ||= domains_subscription_option.pro? && !@domain.current_subscription_plan.delinquent?
    true
  end

  def can_include_page_load_resources_in_audit?
    # @can_include_page_load_resources_in_audit ||= domains_subscription_option.pro? && !@domain.current_subscription_plan.delinquent?
    true
  end

  private

  def domains_subscription_option
    # @domains_subscription_option ||= @domain.selected_subscription_option
  end
end