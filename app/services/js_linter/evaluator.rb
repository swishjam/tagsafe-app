module JsLinter
  class Evaluator
    def initialize(script_change)
      @script_change = script_change
    end

    def evaluate!
      lints.each{ |lint| capture_lint(lint) }
    end

    private

    def capture_lint(lint)
      lint_result = capture_lint_result(lint)
      lint_rule = LintRule.find_by!(rule: lint['ruleId'] || 'unknown')
      create_script_subscriber_lint_results(lint_result, lint_rule)
    end

    def capture_lint_result(lint)
      @script_change.lint_results.create(
        rule_id: lint['ruleId'] || 'unknown',
        message: lint['message'],
        source: lint['source'],
        line: lint['line'],
        column: lint['column'],
        node_type: lint['nodeType'],
        fatal: lint['fatal']
      )
    end

    def create_script_subscriber_lint_results(lint_result, lint_rule)
      script_subscribers_by_script_change_and_lint_rule(lint_rule).each do |script_subscriber|
        script_subscriber.script_subscriber_lint_results.create(lint_result: lint_result)
      end
    end

    def script_subscribers_by_script_change_and_lint_rule(lint_rule)
      ScriptSubscriber.includes(domain: :organization)
                        .where(script_id: @script_change.script.id, domains: { organizations: { id: organization_ids_with_lint_rule(lint_rule) }})
    end

    def organization_ids_with_lint_rule(lint_rule)
      lint_rule.organization_lint_rules.collect(&:organization_id)
    end
    
    def lints
      @lints ||= Eslintrb.lint(@script_change.content.force_encoding('UTF-8'), global_linting_rules)
    end

    def global_linting_rules
      Hash[LintRule.all.collect{ |lint_rule| [lint_rule.rule, 2] }]
    end
  end
end