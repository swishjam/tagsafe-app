require 'rails_helper'

RSpec.describe Audit, type: :model do
  before(:each) do
    prepare_test!
    stub_valid_page_url_enforcement
    stub_tag_version_content
    url_crawl = create(:url_crawl)
    @tag = create(:tag, found_on_url_crawl: url_crawl, found_on_page_url: @domain.page_urls.first)
  end

  describe '#mark_as_most_current_if_possible' do
    it 'sets the Audit as the Tag\'s most_current_audit if it did not fail and ran on either the most recent TagVersion or the live version' do
      audit = create_audit_with_performance_audits(tag: @tag, tag_version: nil, domain: @domain)
      expect(@tag.most_current_audit).to be(nil)
      audit.mark_as_most_current_if_possible
      expect(@tag.most_current_audit).to eq(audit)
    end

    it 'sets the Audit as the Tag\'s most_current_audit if it did not fail and ran on either the live tag version' do
      tv = create_tag_version(tag: @tag)
      audit = create_audit_with_performance_audits(tag: @tag, tag_version: tv, domain: @domain)
      expect(@tag.most_current_audit).to be(nil)
      audit.mark_as_most_current_if_possible
      expect(@tag.most_current_audit).to eq(audit)
    end

    it 'sets the Audit as the Tag\'s most_current_audit if the Audit was performed with a TagVersion that is not the most recent version but the Tag does not have a most_current_audit' do
      old_tv = create_tag_version(tag: @tag, timestamp: 7.days.ago)
      new_tv = create_tag_version(tag: @tag, timestamp: 1.day.ago)
      audit = create_audit_with_performance_audits(tag: @tag, tag_version: old_tv, domain: @domain)
      expect(@tag.most_current_audit).to be(nil)
      audit.mark_as_most_current_if_possible
      expect(@tag.most_current_audit).to eq(audit)
    end

    it 'does not set the Audit as the Tag\'s most_current_audit if the Audit was performed with a TagVersion that is not the most recent version' do
      old_tv = create_tag_version(tag: @tag, timestamp: 7.days.ago)
      new_tv = create_tag_version(tag: @tag, timestamp: 1.day.ago)
      old_tv.update_column :most_recent, false
      new_tv.update_column :most_recent, true

      audit_for_new_tv = create_audit_with_performance_audits(tag: @tag, tag_version: new_tv, domain: @domain)
      audit_for_old_tv = create_audit_with_performance_audits(tag: @tag, tag_version: old_tv, domain: @domain)
      expect(@tag.most_current_audit).to be(nil)
      
      audit_for_new_tv.mark_as_most_current_if_possible
      expect(@tag.most_current_audit).to eq(audit_for_new_tv)

      audit_for_old_tv.mark_as_most_current_if_possible
      expect(@tag.most_current_audit).to eq(audit_for_new_tv)
    end
  end
end