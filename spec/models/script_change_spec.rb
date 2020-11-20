require 'rails_helper'

RSpec.describe ScriptChange, type: :model do
  before(:each) do
    @script = create(:script)
    stub_script_changed_job
  end

  describe '#after_creation' do
    it 'calls the after_create callback upon creation' do
      expect_any_instance_of(ScriptChange).to receive(:after_creation).exactly(:once).and_call_original
      expect_any_instance_of(ScriptChange).to receive(:set_script_content_changed_at_timestamp).exactly(:once).and_call_original
      expect_any_instance_of(ScriptChange).to receive(:make_most_recent!).exactly(:once).and_call_original

      create(:script_change, script: @script)
    end
  end

  describe '#make_most_recent!' do
    it 'makes the first script change the most recent' do
      first_script_change = create(:script_change, script: @script)
      expect(first_script_change.most_recent).to be(true)
      expect(@script.most_recent_change).to eq(first_script_change)
    end

    it 'updates the most recent script change for subsequent script changes' do
      first_script_change = create(:script_change, script: @script)
      expect(first_script_change.most_recent).to be(true)
      expect(@script.most_recent_change).to eq(first_script_change)
      
      second_script_change = create(:script_change, script: @script, hashed_content: 'new hash')
      expect(second_script_change.most_recent).to be(true)
      expect(first_script_change.reload.most_recent).to be(false)
      expect(@script.reload.most_recent_change).to eq(second_script_change)
    end
  end

  describe '#most_recent_first' do
    it 'returns script changes with the most recent first' do
      most_recent_script_change = create(:script_change, script: @script, created_at: DateTime.now)
      older_script_change = create(:script_change, script: @script, hashed_content: 'new hash', created_at: DateTime.yesterday)
      expect(@script.script_changes.most_recent_first.limit(1).first).to eq(most_recent_script_change)
    end
  end

  describe '#previous_change' do
    it 'returns the script change that occured previously' do
      oldest_script_change = create(:script_change, script: @script, hashed_content: 'new hash', created_at: DateTime.yesterday - 1.day)
      middle_script_change = create(:script_change, script: @script, hashed_content: 'another new hash', created_at: DateTime.yesterday)
      most_recent_script_change = create(:script_change, script: @script, created_at: DateTime.now)
      
      expect(most_recent_script_change.previous_change).to eq(middle_script_change)
      expect(middle_script_change.previous_change).to eq(oldest_script_change)
      expect(oldest_script_change.previous_change).to eq(nil)
    end
  end
end