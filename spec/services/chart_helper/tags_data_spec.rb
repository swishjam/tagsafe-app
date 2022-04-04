require 'rails_helper'

RSpec.describe ChartHelper::TagsData do
  before(:each) do
    prepare_test!
    tag = create(:tag, domain: @domain)
    url_to_audit = create(:url_to_audit, tag: tag, audit_url: 'https://www.tagsafe.io', display_url: 'https://www.tagsafe.io')
    two_days_ago = 2.days.ago

    create_tag_version_and_audit_data_for_timestamp(tag, url_to_audit, 7.days.ago) # not included
    create_tag_version_and_audit_data_for_timestamp(tag, url_to_audit, two_days_ago + 1.minute) # not included
    create_tag_version_and_audit_data_for_timestamp(tag, url_to_audit, two_days_ago) # included
    create_tag_version_and_audit_data_for_timestamp(tag, url_to_audit, 1.day.ago) # included
    create_tag_version_and_audit_data_for_timestamp(tag, url_to_audit, 30.minutes.ago) # not included

    @chart_helper = ChartHelper::TagsData.new(tags: @domain.tags, metric_key: 'tagsafe_score', start_time: two_days_ago, end_time: 1.hour.ago)
  end

  def create_tag_version_and_audit_data_for_timestamp(tag, url_to_audit, timestamp)
    tag_version = create(:tag_version, tag: tag, created_at: timestamp)
    audit = create(:audit, 
      tag_version: tag_version, 
      tag: tag,
      audited_url: url_to_audit, 
      execution_reason: ExecutionReason.NEW_RELEASE, 
      performance_audit_calculator: @domain.current_performance_audit_calculator, 
      performance_audit_iterations: 1,
      primary: true
    )
    create(:individual_performance_audit_with_tag, audit: audit, enqueued_at: timestamp - 1.minute, completed_at: timestamp - 2.minutes)
    create(:individual_performance_audit_without_tag, audit: audit, enqueued_at: timestamp - 1.minute, completed_at: timestamp - 2.minutes)
    create(:delta_performance_audit, audit: audit, tagsafe_score: rand(100).to_f)
  end

  describe '#chart_data' do
    it 'only includes data from tag versions created within the timeframe specified' do
      expect(@chart_helper.chart_data.first[:data].count).to be(3)
    end
  end
end