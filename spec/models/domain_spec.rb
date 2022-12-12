require "rails_helper"

RSpec.describe Domain, type: :model do
  before(:each) do
    @container = create(:container)
    @script = create(:script)
  end

  describe '#validations' do
    it 'enforces unique URLs' do
      expect{ create(:container) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#add_tag!' do
    it 'creates a script_subscription for the domain' do
      @container.add_tag!(@script)
      expect(@container.tags.count).to eq(1)
    end

    it 'defaults to active = false' do
      subscription = @container.add_tag!(@script)
      expect(subscription.active).to eq(false)
    end

    it 'sets active = true when passed as an argument' do
      subscription = @container.add_tag!(@script, true)
      expect(subscription.active).to eq(true)
    end
  end

  describe '#has_tag?' do
    it 'returns false if the domain is not yet subscribed' do
      expect(@container.has_tag?(@script)).to eq(false)
      @container.add_tag!(@script)
      expect(@container.has_tag?(@script)).to eq(true)
    end
  end
end