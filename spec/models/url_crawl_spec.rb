require "rails_helper"

RSpec.describe Domain, type: :model do
  before(:each) do
    prepare_test!
    @url_crawl = create(:pending_url_crawl, domain: @domain, url: @domain.url)
    # @url_crawl = UrlCrawl.create!(domain: @domain, url: @domain.url, enqueued_at: Time.now)
  end

  describe '#found_tag!' do
    it 'creates a tag that belongs to the url_crawl and the domain' do
      @url_crawl.found_tag!('https://www.thirdpartytag.com')
      expect(@url_crawl.found_tags).to include('https://www.thirdpartytag.com')
      expect(@domain.tags).to include('https://www.thirdpartytag.com')
    end
  end

  describe '#unremove_tag_from_site!' do
  end

  describe '#query_params_changed_for_tag!' do
  end

  describe '#tag_removed_from_site!' do
  end
end