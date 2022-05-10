module Admin
  class AwsEventBridgeRulesController < BaseController
    def index
      @aws_event_bridge_rules = AwsEventBridgeRule.all.order(enabled: :DESC, name: :ASC)
    end
  end
end