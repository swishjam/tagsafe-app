require 'rails_helper'

RSpec.describe Script, type: :model do
  before(:each) do
    stub_script_changed_job
    stub_script_valid_url_validation
    @domain = create(:domain)
    @script = create(:script)
    @script_change_1 = create(:script_change, script: @script)
  end

  describe '#most_recent_results' do
    it 'returns the most recent script change' do
      expect(@script.most_recent_change).to eq(@script_change_1)
      script_change_2 = create(:script_change, script: @script, hashed_content: 'new_hash')
      @script_change_1.update_column :most_recent, false
      expect(@script.most_recent_change).to eq(script_change_2)
    end
  end

  describe '#with_active_subscribers' do
    it 'only returns scripts that has active script_subscribers' do
      script_without_any_script_subscribers = create(:script, url: 'www.one.com')

      script_with_only_inactive_script_subscribers = create(:script, url: 'www.two.com')
      inactive_script_subscriber = create(:script_subscriber, 
                                            domain: @domain, 
                                            script: script_with_only_inactive_script_subscribers,
                                            active: false)

      script_with_active_script_subscribers = create(:script, url: 'www.three.com')
      active_script_subscriber = create(:script_subscriber,
                                          domain: @domain,
                                          script: script_with_active_script_subscribers)

      expect(Script.with_active_subscribers).to eq([script_with_active_script_subscribers])
    end
  end
end