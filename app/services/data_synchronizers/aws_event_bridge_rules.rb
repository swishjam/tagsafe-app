module DataSynchronizers
  class AwsEventBridgeRules
    def initialize
      @created_rules = 0
      @updated_rules = 0
    end

    def self.import_from_aws
      self.new.import_from_aws
    end

    def import_from_aws
      UptimeRegion.selectable.each do |uptime_region|
        aws_rules = TagsafeAws::EventBridge.list_rules(region: uptime_region.aws_region_name).rules
        aws_rules.each do |aws_rule|
          tagsafe_aws_event_bridge_rule = AwsEventBridgeRule.find_by(region: uptime_region.aws_region_name, name: aws_rule.name)
          if tagsafe_aws_event_bridge_rule.present?
            update_existing_event_bridge_rule(tagsafe_aws_event_bridge_rule, uptime_region, aws_rule)
          else
            create_new_event_bridge_rule(uptime_region, aws_rule)
          end
        end
      end
      puts "Completed sync, created #{@created_rules} new `AwsEventBridgeRules`, updated #{@updated_rules} existing `AwsEventBridgeRules`"
      {
        num_created_rules: @created_rules,
        num_updated_rules: @updated_rules
      }
    end

    private

    def update_existing_event_bridge_rule(tagsafe_aws_event_bridge_rule, uptime_region, aws_rule)
      puts "Updating Tagsafe's AwsEventBridgeRule #{uptime_region.aws_region_name}'s #{aws_rule.name} rule..."
      tagsafe_aws_event_bridge_rule.update!(
        name: aws_rule.name,
        region: uptime_region.aws_region_name,
        enabled: aws_rule.state == 'ENABLED'
      )
      @updated_rules += 1
    end

    def create_new_event_bridge_rule(uptime_region, aws_rule)
      puts "Creating new Tagsafe AwsEventBridgeRule for #{uptime_region.aws_region_name} region: #{aws_rule.name}..."
      klass = if aws_rule.name.include?('uptime-check') then UptimeCheckScheduleAwsEventBridgeRule
              elsif aws_rule.name.include?('release-check') then ReleaseCheckScheduleAwsEventBridgeRule
              else raise "Unidentifiable AWS Event Bridge rule name, must include either `uptime-check` or `release-check` in its name: #{aws_rule.name}"
              end
      klass.create!(
        name: aws_rule.name,
        enabled: aws_rule.state == 'ENABLED',
        region: uptime_region.aws_region_name
      )
      @created_rules += 1
    end
  end
end