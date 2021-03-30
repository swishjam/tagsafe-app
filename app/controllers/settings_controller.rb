class SettingsController < LoggedInController
  def tags
    @script_subscriptions = current_domain.script_subscriptions
                                            .includes(:script)
                                            .order('script_subscribers.should_run_audit DESC')
                                            .order('script_subscribers.removed_from_site_at ASC')
                                            .order('scripts.content_changed_at DESC')
  end

  def linting_rules
    @selectable_lint_rules = LintRule.where.not(id: current_organization.lint_rules.collect(&:id))
  end
end