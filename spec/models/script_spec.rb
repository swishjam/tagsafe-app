require 'rails_helper'

RSpec.describe Script, type: :model do
  before(:each) do
    stub_script_changed_job
    stub_script_valid_url_validation
    @domain = create(:domain)
    @domain_2 = create(:domain, url: 'www.collin.com')
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
    it 'only returns scripts that have active script subscribers' do
      active_script = create(:script, url: 'www.active.com')
      active_script_subscriber = create(:script_subscriber, domain: @domain, script: active_script, active: true)
      inactive_script_subscriber_1 = create(:script_subscriber, domain: @domain_2, script: active_script, active: false)
      
      inactive_script = create(:script, url: 'www.inactive.com')
      inactive_script_subscriber = create(:script_subscriber, domain: @domain, script: inactive_script, active: false)

      expect(Script.with_active_subscribers.include?(active_script)).to eq(true)
      expect(Script.with_active_subscribers.include?(inactive_script)).to eq(false)
    end
  end

  describe '#still_on_site' do
    it 'only returns scripts that have script subscribers still on a site' do
      script_still_on_site = create(:script, url: 'www.active.com')
      active_script_subscriber = create(:script_subscriber, domain: @domain, script: script_still_on_site)
      script_subscriber_not_on_site_1 = create(:script_subscriber, domain: @domain_2, script: script_still_on_site, removed_from_site_at: DateTime.yesterday)
      
      script_not_on_site = create(:script, url: 'www.inactive.com')
      script_subscriber_not_on_site = create(:script_subscriber, domain: @domain, script: script_not_on_site, removed_from_site_at: DateTime.yesterday)

      expect(Script.still_on_site.include?(script_still_on_site)).to eq(true)
      expect(Script.still_on_site.include?(script_not_on_site)).to eq(false)
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