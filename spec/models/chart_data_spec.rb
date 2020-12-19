require 'rails_helper'

RSpec.describe ChartData, type: :model do
  before(:each) do
    stub_script_changed_job
    stub_geppetto_communication
    create_execution_reasons
    @organization = create(:organization)
    @domain = create(:domain, url: 'https://www.tagsafe.io', organization: @organization)
    @script = create(:script, url: 'https://cdn.thirdpartytag.com/js')
    @script_change = create(:script_change, script: @script, created_at: 5.days.ago)
    @script_subscriber = create(:script_subscriber, domain: @domain, script: @script, first_script_change: @script_change)
    @audit = create(:audit, script_change: @script_change, script_subscriber: @script_subscriber, primary: true, execution_reason: ExecutionReason.TAG_CHANGE)
  end

  describe '#update_new_primary_audit' do
  end
end