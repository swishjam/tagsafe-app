require "rails_helper"

RSpec.describe Tag, type: :model do
  before(:each) do
    stub_valid_page_url_enforcement
    stub_all_resque_jobs
    prepare_test!
    @tag = create_tag_with_associations
  end

  describe 'scopes - interval tag checks' do
    it 'returns the correct tags based on the tag preference\'s tag_check_minute_interval' do
      TagPreference::TAG_CHECK_INTERVALS.each do |obj|
        tag = build(:tag, full_url: "https://www.#{obj[:value]}-minute-interval-tag.com", domain: @domain, found_on_page_url: @domain.page_urls.first, found_on_url_crawl: @domain.url_crawls.first)
        tag.tag_preferences.tag_check_minute_interval = obj[:value]
        tag.save!
      end
      expect(Tag.fifteen_minute_interval_checks.count).to be(1)
      expect(Tag.fifteen_minute_interval_checks.first.full_url).to eq("https://www.15-minute-interval-tag.com")
      
      expect(Tag.thirty_minute_interval_checks.count).to be(1)
      expect(Tag.thirty_minute_interval_checks.first.full_url).to eq("https://www.30-minute-interval-tag.com")

      expect(Tag.one_hour_interval_checks.count).to be(1)
      expect(Tag.one_hour_interval_checks.first.full_url).to eq("https://www.60-minute-interval-tag.com")

      expect(Tag.three_hour_interval_checks.count).to be(1)
      expect(Tag.three_hour_interval_checks.first.full_url).to eq("https://www.180-minute-interval-tag.com")

      expect(Tag.six_hour_interval_checks.count).to be(1)
      expect(Tag.six_hour_interval_checks.first.full_url).to eq("https://www.360-minute-interval-tag.com")

      expect(Tag.twelve_hour_interval_checks.count).to be(1)
      expect(Tag.twelve_hour_interval_checks.first.full_url).to eq("https://www.720-minute-interval-tag.com")

      expect(Tag.one_day_interval_checks.count).to be(1)
      expect(Tag.one_day_interval_checks.first.full_url).to eq("https://www.1440-minute-interval-tag.com")
    end
  end

  describe '#after_create' do
    it 'calls apply_defaults' do
      expect_any_instance_of(Tag).to receive(:apply_defaults).exactly(:once)
      create_tag_with_associations(tag_url: 'https://www.apply-defaults-test.com')
    end

    it 'calls run_tag_check_now! if release monitoring is enabled' do
      expect_any_instance_of(Tag).to receive(:run_tag_check_now!).exactly(:once)
      create_tag_with_associations(tag_url: 'https://www.run-tag-check-test-enabled.com')
    end

    it 'doesnt call run_tag_check_now! if release monitoring is disabled' do
      expect_any_instance_of(Tag).to_not receive(:run_tag_check_now!)
      create_tag_with_associations(tag_factory: :disabled_tag, tag_url: 'https://www.run-tag-check-test-disabled.com', )
    end
  end

  describe '#apply_defaults' do
    it 'calls find_and_apply_tag_identifying_data' do
      expect(@tag).to receive(:apply_defaults).exactly(:once)
      @tag.apply_defaults
    end

    it 'enables all functional tests for the domain on the tag' do
      raise 'Implement this test!'
    end
  end

  # describe '#most_recent_version' do
  #   it 'returns the TagVersion where most_recent = true' do
  #     tag_versions = 10.times.map do |i|
  #       tag_check = create(:tag_check, tag: @tag, captured_new_tag_version: true)
  #       create(:tag_version, most_recent: false, tag: @tag, tag_check_captured_with: tag_check, created_at: (rand() * 50).to_i.days.ago)
  #     end
  #   end
  # end

  describe '#find_and_apply_tag_identifying_data' do
    it 'calls TagIdentifyingData.for_tag and updates the tag with the result' do
      expect(TagIdentifyingData).to receive(:for_tag).with(@tag).exactly(:once)
      expect(@tag).to receive(:update!).with(tag_identifying_data: nil).exactly(:once)
      @tag.find_and_apply_tag_identifying_data
    end
  end

  describe '#perform_audit!' do
    it 'calls initializes an AuditRunner and calls .run!' do
      url_to_audit = @tag.urls_to_audit.first
      expect(AuditRunner).to receive(:new).with({
        execution_reason: ExecutionReason.SCHEDULED,
        tag_version: nil,
        tag: @tag,
        initiated_by_domain_user: nil,
        url_to_audit: url_to_audit,
        options: {}
      }).and_call_original
      result = @tag.perform_audit!(
        execution_reason: ExecutionReason.SCHEDULED, 
        tag_version: nil, 
        initiated_by_domain_user: nil, 
        url_to_audit: url_to_audit
      )
      expect(result.tag).to eq(@tag)
    end
  end

  describe '#perform_audit_on_all_urls_on_current_tag_version!' do
    it 'calls #perform_audit_on_all_urls! with tag_version = nil when release_monitoring is disabled' do
      @tag.disable!
      expect(@tag).to receive(:perform_audit_on_all_urls!).with({
        execution_reason: ExecutionReason.SCHEDULED, 
        tag_version: nil,
        initiated_by_domain_user: nil
      }).exactly(:once)
      @tag.perform_audit_on_all_urls_on_current_tag_version!(execution_reason: ExecutionReason.SCHEDULED)
    end

    it 'calls #perform_audit_on_all_urls! with the current tag_version when release_monitoring is enabled' do
      @tag.enable!
      expect(@tag).to receive(:perform_audit_on_all_urls!).with({
        execution_reason: ExecutionReason.SCHEDULED, 
        tag_version: @tag.current_version,
        initiated_by_domain_user: nil
      }).exactly(:once)
      @tag.perform_audit_on_all_urls_on_current_tag_version!(execution_reason: ExecutionReason.SCHEDULED)
    end
  end

  describe '#perform_audit_on_all_urls!' do
    it 'calls perform_audit! on each url_to_audit and returns an array of audits' do
      url_to_audit_1 = @tag.urls_to_audit.first
      page_url = @domain.add_url('https://www.test.com/test', should_scan_for_tags: false)
      url_to_audit_2 = create(:url_to_audit, tag: @tag, page_url: page_url)

      expect(@tag).to receive(:perform_audit!).with({
        execution_reason: ExecutionReason.SCHEDULED,
        tag_version: nil,
        initiated_by_domain_user: nil,
        url_to_audit: url_to_audit_1,
        options: {}
      }).exactly(:once)
      expect(@tag).to receive(:perform_audit!).with({
        execution_reason: ExecutionReason.SCHEDULED,
        tag_version: nil,
        initiated_by_domain_user: nil,
        url_to_audit: url_to_audit_2,
        options: {}
      }).exactly(:once)

      audits = @tag.perform_audit_on_all_urls!(
        execution_reason: ExecutionReason.SCHEDULED, 
        tag_version: nil
      )
      expect(audits.count).to be(2)
    end
  end
end