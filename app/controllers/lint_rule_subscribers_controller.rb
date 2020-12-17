class LintRuleSubscribersController < LoggedInController
  def create
    subscription = LintRuleSubscriber.create(lint_rule_subscriber_params)
    if subscription
      display_toast_message("Added #{subscription.lint_rule.rule} to JS linting rule.")
    else
      display_toast_errors(subscription.errors.full_messages)
    end
    redirect_to request.referrer
  end

  def destroy
    lint_rule_subscriber = LintRuleSubscriber.find(params[:id])
    lint_rule_subscriber.destroy
    display_toast_message("Removed #{lint_rule_subscriber.lint_rule.rule} from JS violation rules.")
    redirect_to request.referrer
  end

  private
  def lint_rule_subscriber_params
    params.require(:lint_rule_subscriber).permit(:subscriber_id, :subscriber_type, :lint_rule_id, :severity)
  end
end