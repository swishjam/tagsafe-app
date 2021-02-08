require 'rails_helper'

RSpec.describe AuditThrottler::Evaluator do
  before(:each) do
    stub_geppetto_communication
    create_execution_reasons
    script = create(:script)
    domain_1 = create(:domain)
    domain_2 = create(:domain, url: 'www.google.com')
    domain_3 = create(:domain, url: 'www.facebook.com')

    @previous_script_change = create(:script_change, script: script, created_at: 10.minutes.ago)
    @new_script_change = create(:script_change, script: script)
    @first_script_change = create(:script_change, script: script, created_at: 10.days.ago)

    @five_minute_throttle_script_subscriber = create(:script_subscriber, script: script, domain: domain_1, throttle_minute_threshold: 5, first_script_change: @first_script_change)
    @fifteen_minute_throttle_script_subscriber = create(:script_subscriber, script: script, domain: domain_2, throttle_minute_threshold: 15, first_script_change: @first_script_change)
    @no_throttle_script_subscriber = create(:script_subscriber, script: script, domain: domain_3, first_script_change: @first_script_change)

    create(:audit, script_change: @previous_script_change, script_subscriber: @five_minute_throttle_script_subscriber, execution_reason: ExecutionReason.TAG_CHANGE)
    create(:audit, script_change: @previous_script_change, script_subscriber: @fifteen_minute_throttle_script_subscriber, execution_reason: ExecutionReason.TAG_CHANGE)
    create(:audit, script_change: @previous_script_change, script_subscriber: @no_throttle_script_subscriber, execution_reason: ExecutionReason.TAG_CHANGE)
    
    @five_minute_throttler = AuditThrottler::Evaluator.new(@five_minute_throttle_script_subscriber)
    @fifteen_minute_throttler = AuditThrottler::Evaluator.new(@fifteen_minute_throttle_script_subscriber)
    @no_throttle_throttler = AuditThrottler::Evaluator.new(@no_throttle_script_subscriber)
  end

  describe '#should_throttle_audit?' do
    it 'returns true when there is an audit that was run due to a tag change within the script_subscribers throttle_minute_threshold' do
      expect(@five_minute_throttler.should_throttle?(@new_script_change)).to be true
      expect(@fifteen_minute_throttler.should_throttle?(@new_script_change)).to be false
      expect(@no_throttle_throttler.should_throttle?(@new_script_change)).to be false
    end

    it 'returns false when there are no audits for the previous script_change' do
      Audit.destroy_all

      expect(@five_minute_throttler.should_throttle?(@new_script_change)).to be false
      expect(@fifteen_minute_throttler.should_throttle?(@new_script_change)).to be false
      expect(@no_throttle_throttler.should_throttle?(@new_script_change)).to be false
    end
  end

  describe '#throttle!' do
    it 'creates a throttled audit' do
       @five_minute_throttler.throttle!(@new_script_change)
       expect(@five_minute_throttle_script_subscriber.reload.primary_audit_by_script_change(@new_script_change).throttled).to be true
    end
  end
end