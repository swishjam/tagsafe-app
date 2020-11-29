require "rails_helper"

RSpec.describe Domain, type: :model do
  # before(:all) do
  #   @domain = create(:domain)
  #   @script = create(:script)
  # end

  before(:each) do
    stub_script_valid_url_validation
    @domain = create(:domain)
    @script = create(:script)
  end

  describe '#validations' do
    it 'enforces unique URLs' do
      expect{ create(:domain) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#subscribe!' do
    it 'creates a script_subscription for the domain' do
      @domain.subscribe!(@script)
      expect(@domain.script_subscriptions.count).to eq(1)
    end

    it 'defaults to active = false' do
      subscription = @domain.subscribe!(@script)
      expect(subscription.active).to eq(false)
    end

    it 'sets active = true when passed as an argument' do
      subscription = @domain.subscribe!(@script, true)
      expect(subscription.active).to eq(true)
    end
  end

  describe '#subscribed_to_script?' do
    it 'returns false if the domain is not yet subscribed' do
      expect(@domain.subscribed_to_script?(@script)).to eq(false)
      @domain.subscribe!(@script)
      expect(@domain.subscribed_to_script?(@script)).to eq(true)
    end
  end
end