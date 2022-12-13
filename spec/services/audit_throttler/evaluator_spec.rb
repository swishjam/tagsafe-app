require 'rails_helper'

RSpec.describe AuditThrottler::Evaluator do
  before(:each) do
    prepare_test!
    domain_1 = create(:container)
    domain_2 = create(:container, url: 'www.google.com')
    domain_3 = create(:container, url: 'www.facebook.com')
    tag_1 = create(:tag, domain: domain_1)

    @previous_tag_version = create(:tag_version, tag: tag, created_at: 10.minutes.ago)
    @new_tag_version = create(:tag_version, tag: tag)
    @first_tag_version = create(:tag_version, tag: tag, created_at: 10.days.ago)

    @five_minute_throttle_tag = create(:tag, tag: tag, domain: domain_1, throttle_minute_threshold: 5, first_tag_version: @first_tag_version)
    @fifteen_minute_throttle_tag = create(:tag, tag: tag, domain: domain_2, throttle_minute_threshold: 15, first_tag_version: @first_tag_version)
    @no_throttle_tag = create(:tag, tag: tag, domain: domain_3, first_tag_version: @first_tag_version)

    create(:audit, tag_version: @previous_tag_version, tag: @five_minute_throttle_tag, execution_reason: ExecutionReason.NEW_RELEASE)
    create(:audit, tag_version: @previous_tag_version, tag: @fifteen_minute_throttle_tag, execution_reason: ExecutionReason.NEW_RELEASE)
    create(:audit, tag_version: @previous_tag_version, tag: @no_throttle_tag, execution_reason: ExecutionReason.NEW_RELEASE)
    
    @five_minute_throttler = AuditThrottler::Evaluator.new(@five_minute_throttle_tag)
    @fifteen_minute_throttler = AuditThrottler::Evaluator.new(@fifteen_minute_throttle_tag)
    @no_throttle_throttler = AuditThrottler::Evaluator.new(@no_throttle_tag)
  end

  describe '#should_throttle_audit?' do
    it 'returns true when there is an audit that was run due to a tag change within the tags throttle_minute_threshold' do
      expect(@five_minute_throttler.should_throttle?(@new_tag_version)).to be true
      expect(@fifteen_minute_throttler.should_throttle?(@new_tag_version)).to be false
      expect(@no_throttle_throttler.should_throttle?(@new_tag_version)).to be false
    end

    it 'returns false when there are no audits for the previous tag_version' do
      Audit.destroy_all

      expect(@five_minute_throttler.should_throttle?(@new_tag_version)).to be false
      expect(@fifteen_minute_throttler.should_throttle?(@new_tag_version)).to be false
      expect(@no_throttle_throttler.should_throttle?(@new_tag_version)).to be false
    end
  end

  describe '#throttle!' do
    it 'creates a throttled audit' do
       @five_minute_throttler.throttle!(@new_tag_version)
       expect(@new_tag_version.primary_audit.throttled).to be true
    end
  end
end