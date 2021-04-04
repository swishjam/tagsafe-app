require 'rails_helper'

RSpec.describe ChartData, type: :model do
  before(:each) do
    stub_tag_versiond_job
    stub_geppetto_communication
    create_execution_reasons
    @organization = create(:organization)
    @domain = create(:domain, url: 'https://www.tagsafe.io', organization: @organization)
    @script = create(:script, url: 'https://cdn.thirdpartytag.com/js')
    @tag_version = create(:tag_version, script: @script, created_at: 5.days.ago)
    @tag = create(:tag, domain: @domain, script: @script, first_tag_version: @tag_version)
    @audit = create(:audit, tag_version: @tag_version, tag: @tag, primary: true, execution_reason: ExecutionReason.TAG_CHANGE)
  end

  describe '#update_new_primary_audit' do
  end
end