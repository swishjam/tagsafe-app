require 'rails_helper'

RSpec.describe TagVersion, type: :model do
  before(:each) do
    @script = create(:script)
    stub_tag_versiond_job
  end

  describe '#after_creation' do
    it 'calls the after_create callback upon creation' do
      expect_any_instance_of(TagVersion).to receive(:after_creation).exactly(:once).and_call_original
      expect_any_instance_of(TagVersion).to receive(:set_script_content_changed_at_timestamp).exactly(:once).and_call_original
      expect_any_instance_of(TagVersion).to receive(:make_most_recent!).exactly(:once).and_call_original

      create(:tag_version, script: @script)
    end
  end

  describe '#make_most_recent!' do
    it 'makes the first script change the most recent' do
      first_tag_version = create(:tag_version, script: @script)
      expect(first_tag_version.most_recent).to be(true)
      expect(@script.most_recent_version).to eq(first_tag_version)
    end

    it 'updates the most recent script change for subsequent script changes' do
      first_tag_version = create(:tag_version, script: @script)
      expect(first_tag_version.most_recent).to be(true)
      expect(@script.most_recent_version).to eq(first_tag_version)
      
      second_tag_version = create(:tag_version, script: @script, hashed_content: 'new hash')
      expect(second_tag_version.most_recent).to be(true)
      expect(first_tag_version.reload.most_recent).to be(false)
      expect(@script.reload.most_recent_version).to eq(second_tag_version)
    end
  end

  describe '#most_recent_first' do
    it 'returns script changes with the most recent first' do
      most_recent_tag_version = create(:tag_version, script: @script, created_at: DateTime.now)
      older_tag_version = create(:tag_version, script: @script, hashed_content: 'new hash', created_at: DateTime.yesterday)
      expect(@script.tag_versions.most_recent_first.limit(1).first).to eq(most_recent_tag_version)
    end
  end

  describe '#previous_version' do
    it 'returns the script change that occured previously' do
      oldest_tag_version = create(:tag_version, script: @script, hashed_content: 'new hash', created_at: DateTime.yesterday - 1.day)
      middle_tag_version = create(:tag_version, script: @script, hashed_content: 'another new hash', created_at: DateTime.yesterday)
      most_recent_tag_version = create(:tag_version, script: @script, created_at: DateTime.now)
      
      expect(most_recent_tag_version.previous_version).to eq(middle_tag_version)
      expect(middle_tag_version.previous_version).to eq(oldest_tag_version)
      expect(oldest_tag_version.previous_version).to eq(nil)
    end
  end
end