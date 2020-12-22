class SettingsController < LoggedInController
  def tags
    @script_subscriptions = current_domain.script_subscriptions
  end

  def linting_rules
    @selectable_lint_rules = LintRule.where.not(id: current_organization.lint_rules.collect(&:id))
  end
end