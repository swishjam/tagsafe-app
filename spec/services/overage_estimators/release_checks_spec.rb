require 'rails_helper'

RSpec.describe OverageEstimators::ReleaseChecks do
  before(:each) do
    prepare_test!
    num_release_checks_at_every_12_hours = 2 * 30
    @subscription_features_configuration = create(:subscription_features_configuration_zero_features, release_checks_included_per_month: num_release_checks_at_every_12_hours, domain: @domain)
    create_aws_event_bridge_rules
    @tag = create_tag_with_associations
  end

  describe '#price_would_increase?' do
    it 'returns true if the user is lowing their release check interval, increasing their costs' do
      @tag.tag_preferences.update_column(:release_check_minute_interval, 30)
      overage_estimator = OverageEstimators::ReleaseChecks.new(domain: @domain, tag: @tag, new_release_check_interval: 15)
      expect(overage_estimator.price_would_increase?).to be(true)
    end

    it 'returns false if the user is increasing their release check interval, lowering their costs' do
      @tag.tag_preferences.update_column(:release_check_minute_interval, 15)
      overage_estimator = OverageEstimators::ReleaseChecks.new(domain: @domain, tag: @tag, new_release_check_interval: 30)
      expect(overage_estimator.price_would_increase?).to be(false)
    end
  end
  
  describe '#would_exceed_included_usage_for_subscription_package?' do
    it 'returns true when the new release_check_minute_interval would result in more ReleaseChecks alloted for their Subscription package' do
      overage_estimator = OverageEstimators::ReleaseChecks.new(domain: @domain, tag: @tag, new_release_check_interval: 1)
      expect(overage_estimator.would_exceed_included_usage_for_subscription_package?).to be(true)
    end

    it 'returns false when the new release_check_minute_interval would result in the exact ReleaseChecks alloted for their Subscription package' do
      minutes_in_next_month = (Time.current.next_month.end_of_month - Time.current.next_month.beginning_of_month) / 1.day
      exact_num_release_checks_per_day_for_subscription_package = (@domain.subscription_features_configuration.release_checks_included_per_month / minutes_in_next_month).round
      overage_estimator = OverageEstimators::ReleaseChecks.new(domain: @domain, tag: @tag, new_release_check_interval: 1_440/exact_num_release_checks_per_day_for_subscription_package)
      expect(overage_estimator.would_exceed_included_usage_for_subscription_package?).to be(false)
    end

    it 'returns false when the new release_check_minute_interval would result in less ReleaseChecks alloted for their Subscription package' do
      overage_estimator = OverageEstimators::ReleaseChecks.new(domain: @domain, tag: @tag, new_release_check_interval: 1_440)
      expect(overage_estimator.would_exceed_included_usage_for_subscription_package?).to be(false)
    end
  end

  describe '#expected_total_usage_next_month_on_current_config' do
    it 'returns the expected number of release checks for the domain\'s current release check config' do
      @tag.tag_preferences.update_column :release_check_minute_interval, 1
      overage_estimator = OverageEstimators::ReleaseChecks.new(domain: @domain, tag: @tag, new_release_check_interval: 1_440)
      expected_num_release_checks_next_month = (Time.current.next_month.end_of_month - Time.current.next_month.beginning_of_month) / 1.minute
      expect(overage_estimator.expected_total_usage_next_month_on_current_config).to eq(expected_num_release_checks_next_month.ceil)
    end
  end

  describe '#expected_dollar_overage_next_month_on_current_config' do
    it 'returns the cost of the domain\'s current release check configuration, excluding the included_release_checks_per_month in their subscription_features_configuration' do
      @tag.tag_preferences.update_column :release_check_minute_interval, 1
      overage_estimator = OverageEstimators::ReleaseChecks.new(domain: @domain, tag: @tag, new_release_check_interval: 1_440)
      expected_num_release_checks_next_month = (Time.current.next_month.end_of_month - Time.current.next_month.beginning_of_month) / 1.minute
      expected_cost_of_release_checks_next_month = (expected_num_release_checks_next_month - @domain.subscription_features_configuration.release_checks_included_per_month)*OverageEstimators::ReleaseChecks::COST_PER_RELEASE_CHECK_IN_DOLLARS
      expect(overage_estimator.expected_dollar_overage_next_month_on_current_config).to eq(expected_cost_of_release_checks_next_month.round(2))
    end
  end

  describe '#expected_total_usage_next_month_on_proposed_config' do
    it 'returns the expected number of release checks for the domain\'s under the proposed release check config' do
      @tag.tag_preferences.update_column :release_check_minute_interval, 1
      overage_estimator = OverageEstimators::ReleaseChecks.new(domain: @domain, tag: @tag, new_release_check_interval: 180)
      minutes_in_next_month = (Time.current.next_month.end_of_month - Time.current.next_month.beginning_of_month) / 1.minute
      expected_num_release_checks_next_month = minutes_in_next_month / 180
      expect(overage_estimator.expected_total_usage_next_month_on_proposed_config).to eq(expected_num_release_checks_next_month.ceil)
    end
  end

  describe '#expected_dollar_overage_next_month_on_proposed_config' do
    it 'returns the cost of the domain\'s current release check configuration, excluding the included_release_checks_per_month in their subscription_features_configuration' do
      @tag.tag_preferences.update_column :release_check_minute_interval, 1
      overage_estimator = OverageEstimators::ReleaseChecks.new(domain: @domain, tag: @tag, new_release_check_interval: 180)
      minutes_in_next_month = (Time.current.next_month.end_of_month - Time.current.next_month.beginning_of_month) / 1.minute
      expected_num_release_checks_next_month = minutes_in_next_month / 180
      expected_cost_of_release_checks_next_month = (expected_num_release_checks_next_month - @domain.subscription_features_configuration.release_checks_included_per_month)*OverageEstimators::ReleaseChecks::COST_PER_RELEASE_CHECK_IN_DOLLARS
      expect(overage_estimator.expected_dollar_overage_next_month_on_proposed_config).to eq(expected_cost_of_release_checks_next_month.round(2))
    end
  end
end