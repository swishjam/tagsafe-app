require 'rails_helper'

RSpec.describe DataRetention::TagVersions do
  before(:each) do
    stub_geppetto_communication
    create_execution_reasons

    organization = create(:organization)
    script = create(:script)
    domain1 = create(:domain, organization: organization)
    domain2 = create(:domain, url: 'https://www.google.com', organization: organization)
    domain3 = create(:domain, url: 'https://www.stripe.com', organization: organization)

    @most_recent_tag_version = create(:tag_version, script: script, hashed_content: 'blah', created_at: Time.now)
    @oldest_tag_version = create(:tag_version, script: script, created_at: 1.day.ago)
    @middle_tag_version1 = create(:tag_version, script: script, hashed_content: 'blahblahblah', created_at: 12.hours.ago)
    @middle_tag_version2 = create(:tag_version, script: script, hashed_content: 'blahblah', created_at: 6.hours.ago)

    domain1.add_tag!(script, first_tag_version: @oldest_tag_version, tag_version_retention_count: 1)
    domain2.add_tag!(script, first_tag_version: @oldest_tag_version, tag_version_retention_count: 2)
    domain3.add_tag!(script, first_tag_version: @oldest_tag_version, tag_version_retention_count: 3)

    @tag_version_retention = DataRetention::TagVersions.new(@most_recent_tag_version)
  end

  describe '#records' do
    it 'returns the tag_versions outside of the retention_count' do
      expect(@tag_version_retention.records_to_purge).to include(@oldest_tag_version)
      expect(@tag_version_retention.records_to_purge).to_not include(@most_recent_tag_version)
      expect(@tag_version_retention.records_to_purge).to_not include(@middle_tag_version1)
      expect(@tag_version_retention.records_to_purge).to_not include(@middle_tag_version2)
    end
  end

  describe '#highest_retention_count' do
    it 'returns the highest tag_version_retention_count of all the tag_version\'s tags' do
      expect(@tag_version_retention.highest_retention_count).to be(3)
    end
  end
end