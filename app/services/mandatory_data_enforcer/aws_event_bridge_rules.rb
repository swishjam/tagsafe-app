module MandatoryDataEnforcer
  class AwsEventBridgeRules
    def initialize(update_existing: true)
      @created_rules = 0
      @updated_rules = 0
      @update_existing = update_existing
    end

    def self.validate!(update_existing: true)
      self.new(update_existing: update_existing).import_or_update_event_bridge_rules_from_aws
      verify_required_uptime_and_release_check_event_bridge_rules_exist!
    end

    def import_or_update_event_bridge_rules_from_aws
      UptimeRegion::SELECTABLE_AWS_REGION_NAMES.each do |region_name|
        aws_rules = TagsafeAws::EventBridge.list_rules(region: region_name).rules
        aws_rules.each do |aws_rule|
          tagsafe_aws_event_bridge_rule = AwsEventBridgeRule.find_by(region: region_name, name: aws_rule.name)
          if tagsafe_aws_event_bridge_rule.present?
            tagsafe_aws_event_bridge_rule.fetch_from_aws
            next unless @update_existing
            update_existing_event_bridge_rule(tagsafe_aws_event_bridge_rule, region_name, aws_rule)
          else
            create_new_event_bridge_rule(region_name, aws_rule)
          end
        end
      end
      Rails.logger.info "Completed sync, created #{@created_rules} new `AwsEventBridgeRules`, updated #{@updated_rules} existing `AwsEventBridgeRules`"
      {
        num_created_rules: @created_rules,
        num_updated_rules: @updated_rules
      }
    end

    private

    def self.verify_required_uptime_and_release_check_event_bridge_rules_exist!
      TagPreference.SUPPORTED_RELEASE_CHECK_INTERVALS.each do |release_check_minute_interval|
        ReleaseCheckScheduleAwsEventBridgeRule.for_interval!(release_check_minute_interval)
      end
      UptimeRegion::SELECTABLE_AWS_REGION_NAMES.each do |aws_region_name|
        UptimeCheckScheduleAwsEventBridgeRule.for_region_name!(aws_region_name)
      end
      Rails.logger.info "Validates all AwsEventBridgeRules present."
    end

    private

    def update_existing_event_bridge_rule(tagsafe_aws_event_bridge_rule, region_name, aws_rule)
      puts "Updating Tagsafe's AwsEventBridgeRule #{region_name}'s #{aws_rule.name} rule..."
      tagsafe_aws_event_bridge_rule.update!(
        name: aws_rule.name,
        region: region_name,
        enabled: aws_rule.state == 'ENABLED'
      )
      @updated_rules += 1
    end

    def create_new_event_bridge_rule(region_name, aws_rule)
      puts "Creating new Tagsafe AwsEventBridgeRule for #{region_name} region: #{aws_rule.name}..."
      klass = if aws_rule.name.include?('uptime-check') then UptimeCheckScheduleAwsEventBridgeRule
              elsif aws_rule.name.include?('release-check') then ReleaseCheckScheduleAwsEventBridgeRule
              else raise "Unidentifiable AWS Event Bridge rule name, must include either `uptime-check` or `release-check` in its name: #{aws_rule.name}"
              end
      klass.create!(
        name: aws_rule.name,
        enabled: aws_rule.state == 'ENABLED',
        region: region_name
      )
      @created_rules += 1
    end
  end
end