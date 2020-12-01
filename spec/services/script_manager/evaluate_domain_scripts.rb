require 'rails_helper'

RSpec.describe ScriptManager::EvaluateDomainScripts do
  before(:each) do
    stub_evaluate_script_job
    @domain = create(:domain)

    @existing_script_1 = create(:script, url: 'https://cdn.instagram.com/script.js')
    @existing_script_2 = create(:script, url: 'https://cdn.google.com/script.js')
    @existing_script_3 = create(:script, url: 'https://cdn.facebook.com/script.js')
    @existing_script_4 = create(:script, url: 'https://cdn.collin.com/script.js')

    @script_subscriber_1 = create(:script_subscriber, domain: @domain, script: @existing_script_1)
    @script_subscriber_2 = create(:script_subscriber, domain: @domain, script: @existing_script_2)
    @script_subscriber_3 = create(:script_subscriber, domain: @domain, script: @existing_script_3)

    @new_script_urls = %w[https://cdn.twitter.com/script.js https://cdn.google.com/script.js https://cdn.instagram.com/script.js]
    @removed_from_site_script_urls = %w[https://cdn.facebook.com/script.js]

    @evaluator = ScriptManager::EvaluateDomainScripts.new(@domain, @new_script_urls)
    @evaluator.evaluate!
  end

  describe '#evaluate!' do
    it 'saves scripts that are still on the site' do
      urls_still_on_site = @domain.script_subscriptions.still_on_site.collect{ |ss| ss.script.url }
      urls_no_longer_on_site = @domain.script_subscriptions.no_longer_on_site.collect{ |ss| ss.script.url }
      @new_script_urls.each do |url|
        expect(urls_still_on_site.include?(url)).to eq(true)
        expect(urls_no_longer_on_site.include?(url)).to eq(false)
      end
    end

    it 'removes scripts that are no longer on the site' do
      urls_still_on_site = @domain.script_subscriptions.still_on_site.collect{ |ss| ss.script.url }
      urls_no_longer_on_site = @domain.script_subscriptions.no_longer_on_site.collect{ |ss| ss.script.url }
      @removed_from_site_script_urls.each do |url|
        expect(urls_still_on_site.include?(url)).to eq(false)
        expect(urls_no_longer_on_site.include?(url)).to eq(true)
      end
    end
  end
end