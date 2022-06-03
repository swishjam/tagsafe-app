require 'rails_helper'

RSpec.describe AuditHandler::RunnerOptions do
  before(:each) do
    prepare_test!
    @tag = create_tag_with_associations
  end

  describe '#initialize' do
    it 'throws an error if an invalid option is passed' do
      expect{ 
        AuditHandler::RunnerOptions.new(@tag, foo: 'bar') 
      }.to raise_error(AuditHandler::RunnerOptions::InvalidOptionError)
    end

    it 'is valid when no options are passed' do
      AuditHandler::RunnerOptions.new(@tag, {})
    end
  end
end