class SettingsController < LoggedInController
  def linting_rules
    @lint_rule_subscriptions = current_organization.lint_rule_subscriptions.joins(:lint_rule)
    @selectable_lint_rules = LintRule.where.not(id: @lint_rule_subscriptions.collect(&:lint_rule_id))
  end
end