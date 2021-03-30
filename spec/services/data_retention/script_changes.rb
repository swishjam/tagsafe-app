require 'rails_helper'

RSpec.describe DataRetention::ScriptChanges do
  before(:each) do
    stub_geppetto_communication
    create_execution_reasons

    organization = create(:organization)
    script = create(:script)
    domain1 = create(:domain, organization: organization)
    domain2 = create(:domain, url: 'https://www.google.com', organization: organization)
    domain3 = create(:domain, url: 'https://www.stripe.com', organization: organization)

    @most_recent_script_change = create(:script_change, script: script, hashed_content: 'blah', created_at: Time.now)
    @oldest_script_change = create(:script_change, script: script, created_at: 1.day.ago)
    @middle_script_change1 = create(:script_change, script: script, hashed_content: 'blahblahblah', created_at: 12.hours.ago)
    @middle_script_change2 = create(:script_change, script: script, hashed_content: 'blahblah', created_at: 6.hours.ago)

    domain1.subscribe!(script, first_script_change: @oldest_script_change, script_change_retention_count: 1)
    domain2.subscribe!(script, first_script_change: @oldest_script_change, script_change_retention_count: 2)
    domain3.subscribe!(script, first_script_change: @oldest_script_change, script_change_retention_count: 3)

    @script_change_retention = DataRetention::ScriptChanges.new(@most_recent_script_change)
  end

  describe '#records' do
    it 'returns the script_changes outside of the retention_count' do
      expect(@script_change_retention.records_to_purge).to include(@oldest_script_change)
      expect(@script_change_retention.records_to_purge).to_not include(@most_recent_script_change)
      expect(@script_change_retention.records_to_purge).to_not include(@middle_script_change1)
      expect(@script_change_retention.records_to_purge).to_not include(@middle_script_change2)
    end
  end

  describe '#highest_retention_count' do
    it 'returns the highest script_change_retention_count of all the script_change\'s script_subscribers' do
      expect(@script_change_retention.highest_retention_count).to be(3)
    end
  end
end