require 'rails_helper'

RSpec.describe TagManager::EvaluateUrlCrawlFoundTags do
  before(:each) do
    prepare_test!
    create(:non_third_party_url_pattern, pattern: 'dontcaptureme', domain: @domain)
    crawl = create(:pending_url_crawl, domain: @domain, url: "#{@domain.url}/crawl")

    tag_urls_already_on_site = %w[
      https://cdn.facebook.com/script.js 
      https://www.thirdpartytag.com/js?a_query_param_that_changes_often=foo
      https://cdn.twitter.com/script.js
    ]
    tag_urls_received = %w[
      https://cdn.twitter.com/script.js 
      https://cdn.google.com/script.js 
      https://cdn.instagram.com/script.js 
      https://www.thirdpartytag.com/js?a_new_param=bar 
      https://www.queryparameter.com/script.js?a_new_query_param_has_emerged=baz 
      https://www.removed.com/js
      https://www.another-remove-tag.com/script.js?a_brand_new_query_parameter=hello
      https://www.the-last-removed-tag.com/script.js?some_other_new_query_params=foo
      https://www.dontcaptureme.com/script.js
    ]
    tag_urls_to_consider_query_param_changes_new_tag = %w[
      https://www.queryparameter.com/script.js?an_old_query_param_that_is_about_to_change=hievaluate_individual_results_spec.rb
    ]
    tag_urls_that_are_already_removed_from_site = %w[
      https://www.removed.com/js
      https://www.another-remove-tag.com/script.js?stale_query_params=hello
    ]
    tag_urls_that_are_already_removed_from_site_consider_query_param_changes_new_tag = %w[
      https://www.the-last-removed-tag.com/script.js?stale_query_params=hello
    ]

    tag_urls_already_on_site.each do |url|
      parsed_url = URI.parse(url)
      create(:tag,
        full_url: url,
        url_domain: parsed_url.host,
        url_path: parsed_url.path, 
        url_query_param: parsed_url.query,
        domain: @domain,
        # consider_query_param_changes_new_tag: false
      )
    end

    tag_urls_to_consider_query_param_changes_new_tag.each do |url|
      parsed_url = URI.parse(url)
      create(:tag,
        full_url: url,
        url_domain: parsed_url.host,
        url_path: parsed_url.path, 
        url_query_param: parsed_url.query,
        domain: @domain,
        # consider_query_param_changes_new_tag: true
      )
    end

    tag_urls_that_are_already_removed_from_site.each do |url|
      parsed_url = URI.parse(url)
      create(:tag,
        full_url: url,
        url_domain: parsed_url.host,
        url_path: parsed_url.path,
        url_query_param: parsed_url.query,
        domain: @domain,
        # consider_query_param_changes_new_tag: false,
        removed_from_site_at: 1.day.ago
      )
    end

    tag_urls_that_are_already_removed_from_site_consider_query_param_changes_new_tag.each do |url|
      parsed_url = URI.parse(url)
      create(:tag,
        full_url: url,
        url_domain: parsed_url.host,
        url_path: parsed_url.path,
        url_query_param: parsed_url.query,
        domain: @domain,
        # consider_query_param_changes_new_tag: true,
        removed_from_site_at: 1.day.ago
      )
    end

    @evaluator = TagManager::EvaluateUrlCrawlFoundTags.new(url_crawl: crawl, tag_urls: tag_urls_received)
    @evaluator.evaluate!
    
    @tag_urls_on_site = @domain.tags.collect(&:full_url)
    @tag_urls_removed_from_site = @domain.tags.removed.collect(&:full_url)
  end

  describe '#evaluate!' do
    it "updates the domain's current tags based on the received URLs" do
      expect(@tag_urls_on_site).to include('https://cdn.twitter.com/script.js')
      expect(@tag_urls_on_site).to include('https://cdn.google.com/script.js')
      expect(@tag_urls_on_site).to include('https://cdn.instagram.com/script.js')
      expect(@tag_urls_on_site).to include('https://cdn.instagram.com/script.js')
    end

    it "updates the existing tag's query parameters and doesn't create a new record when the received tag is a change to an existing tag's query parameters when consider_query_param_changes_new_tag = false" do
      expect(@tag_urls_on_site).to include('https://www.thirdpartytag.com/js?a_new_param=bar')
      expect(@tag_urls_removed_from_site).to_not include('https://www.thirdpartytag.com/js?a_query_param_that_changes_often=foo')
    end

    it "creates a new tag when a received tag url is received with a query parameter change to an existing tag, but the tag's consider_query_param_changes_new_tag = true" do
      expect(@tag_urls_on_site).to include('https://www.queryparameter.com/script.js?a_new_query_param_has_emerged=baz')
      expect(@tag_urls_removed_from_site).to include('https://www.queryparameter.com/script.js?an_old_query_param_that_is_about_to_change=hi')
    end

    it "removes any tags that existed on the domain previously, but were not received as the new incoming tags" do
      expect(@tag_urls_removed_from_site).to include('https://cdn.facebook.com/script.js')
    end

    it "re-adds any tags that were once removed but were re-provided as a new tag" do
      expect(@tag_urls_on_site).to include('https://www.removed.com/js')
    end

    it "re-adds any tags that were once removed but were re-provided as a new tag and have new query parameters and the pre-existing tag has consider_query_param_changes_new_tag = true" do
      expect(@tag_urls_on_site).to include('https://www.another-remove-tag.com/script.js?a_brand_new_query_parameter=hello')
      expect(@tag_urls_on_site).to_not include('https://www.another-remove-tag.com/script.js?stale_query_params=hello')
    end

    it "creates a new tag when a provided tag url already exists but was removed from the site and has new query parameters and the pre-existing tag has consider_query_param_changes_new_tag = false" do
      expect(@tag_urls_on_site).to include('https://www.the-last-removed-tag.com/script.js?some_other_new_query_params=foo')
      expect(@tag_urls_removed_from_site).to include('https://www.the-last-removed-tag.com/script.js?stale_query_params=hello')
    end

    it "ignores any tags that match the domain's non_third_party_url_pattern" do
      expect(@tag_urls_on_site).to_not include('https://www.dontcaptureme.com/script.js')
    end
  end
end