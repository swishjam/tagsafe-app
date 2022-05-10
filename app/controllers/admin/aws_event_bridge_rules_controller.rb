module Admin
  class AwsEventBridgeRulesController < BaseController
    def index
      @aws_event_bridge_rules = AwsEventBridgeRule.all.order(:name)
    end
  end
end