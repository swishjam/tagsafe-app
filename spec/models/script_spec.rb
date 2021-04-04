require 'rails_helper'

RSpec.describe Tag, type: :model do
  before(:each) do
    stub_tag_versiond_job
    stub_script_valid_url_validation
    @domain = create(:domain)
    @domain_2 = create(:domain, url: 'www.collin.com')
    @script = create(:script)
    @tag_version_1 = create(:tag_version, script: @script)
  end

  describe '#most_recent_results' do
    it 'returns the most recent script change' do
      expect(@script.most_recent_version).to eq(@tag_version_1)
      tag_version_2 = create(:tag_version, script: @script, hashed_content: 'new_hash')
      @tag_version_1.update_column :most_recent, false
      expect(@script.most_recent_version).to eq(tag_version_2)
    end
  end

  describe '#with_active_subscribers' do
    it 'only returns scripts that have active script subscribers' do
      active_script = create(:script, url: 'www.active.com')
      active_tag = create(:tag, domain: @domain, script: active_script, active: true)
      inactive_tag_1 = create(:tag, domain: @domain_2, script: active_script, active: false)
      
      inactive_script = create(:script, url: 'www.inactive.com')
      inactive_tag = create(:tag, domain: @domain, script: inactive_script, active: false)

      expect(Tag.with_active_subscribers.include?(active_script)).to eq(true)
      expect(Tag.with_active_subscribers.include?(inactive_script)).to eq(false)
    end
  end

  describe '#still_on_site' do
    it 'only returns scripts that have script subscribers still on a site' do
      script_still_on_site = create(:script, url: 'www.active.com')
      active_tag = create(:tag, domain: @domain, script: script_still_on_site)
      tag_not_on_site_1 = create(:tag, domain: @domain_2, script: script_still_on_site, removed_from_site_at: DateTime.yesterday)
      
      script_not_on_site = create(:script, url: 'www.inactive.com')
      tag_not_on_site = create(:tag, domain: @domain, script: script_not_on_site, removed_from_site_at: DateTime.yesterday)

      expect(Tag.still_on_site.include?(script_still_on_site)).to eq(true)
      expect(Tag.still_on_site.include?(script_not_on_site)).to eq(false)
    end
  end

  describe '#with_active_subscribers' do
    it 'only returns scripts that has active tags' do
      script_without_any_tags = create(:script, url: 'www.one.com')

      script_with_only_inactive_tags = create(:script, url: 'www.two.com')
      inactive_tag = create(:tag, 
                                            domain: @domain, 
                                            script: script_with_only_inactive_tags,
                                            active: false)

      script_with_active_tags = create(:script, url: 'www.three.com')
      active_tag = create(:tag,
                                          domain: @domain,
                                          script: script_with_active_tags)

      expect(Tag.with_active_subscribers).to eq([script_with_active_tags])
    end
  end
end