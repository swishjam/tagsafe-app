require 'rails_helper'

RSpec.describe HoneycombChartFormatter do
  before(:each) do
    prepare_test!
  end

  def create_tags(num_tags)
    url_crawl = create(:completed_url_crawl, domain: @container, page_url: @container.page_urls.first)
    num_tags.times.map do
      url = Faker::Internet.unique.url(path: '/script.js')
      create(:tag, 
        domain: @container, 
        full_url: url, 
        url_domain: URI.parse(url).hostname, 
        url_path: '/script.js', 
        found_on_page_url: @container.page_urls.first, 
        found_on_url_crawl: url_crawl
      )
    end
  end

  describe '#format_rows!' do
    it 'returns the correct rows when there are 5 tags' do
      tags = create_tags(5)
      formatter = HoneycombChartFormatter.new(tags.dup)
      rows = formatter.format_rows!
      expect(rows[0].count).to be(2)
      expect(rows[1].count).to be(3)
      expect(rows[2]).to be(nil)
      expect(rows.flatten.collect(&:id).sort).to eq(tags.collect(&:id).sort)
      expect(rows.flatten.count).to be(5)
    end

    it 'returns the correct rows when there are 7 tags' do
      tags = create_tags(7)
      formatter = HoneycombChartFormatter.new(tags.dup)
      rows = formatter.format_rows!
      expect(rows[0].count).to be(3)
      expect(rows[1].count).to be(4)
      expect(rows[2]).to be(nil)
      expect(rows.flatten.collect(&:id).sort).to eq(tags.collect(&:id).sort)
      expect(rows.flatten.count).to be(7)
    end

    it 'returns the correct rows when there are 10 tags' do
      tags = create_tags(10)
      formatter = HoneycombChartFormatter.new(tags.dup)
      rows = formatter.format_rows!
      expect(rows[0].count).to be(3)
      expect(rows[1].count).to be(4)
      expect(rows[2].count).to be(3)
      expect(rows[3]).to be(nil)
      expect(rows.flatten.collect(&:id).sort).to eq(tags.collect(&:id).sort)
      expect(rows.flatten.count).to be(10)
    end

    it 'returns the correct rows when there are 12 tags' do
      tags = create_tags(12)
      formatter = HoneycombChartFormatter.new(tags.dup)
      rows = formatter.format_rows!
      expect(rows[0].count).to be(3)
      expect(rows[1].count).to be(4)
      expect(rows[2].count).to be(3)
      expect(rows[3].count).to be(2)
      expect(rows[4]).to be(nil)
      expect(rows.flatten.collect(&:id).sort).to eq(tags.collect(&:id).sort)
      expect(rows.flatten.count).to be(12)
    end

    it 'returns the correct rows when there are 15 tags' do
      tags = create_tags(15)
      formatter = HoneycombChartFormatter.new(tags.dup)
      rows = formatter.format_rows!
      expect(rows[0].count).to be(3)
      expect(rows[1].count).to be(4)
      expect(rows[2].count).to be(5)
      expect(rows[3].count).to be(3)
      expect(rows[4]).to be(nil)
      expect(rows.flatten.collect(&:id).sort).to eq(tags.collect(&:id).sort)
      expect(rows.flatten.count).to be(15)
    end

    it 'returns the correct rows when there are 20 tags' do
      tags = create_tags(20)
      formatter = HoneycombChartFormatter.new(tags.dup)
      rows = formatter.format_rows!
      expect(rows[0].count).to be(3)
      expect(rows[1].count).to be(4)
      expect(rows[2].count).to be(5)
      expect(rows[3].count).to be(4)
      expect(rows[4].count).to be(3)
      expect(rows[5].count).to be(1)
      expect(rows[6]).to be(nil)
      expect(rows.flatten.collect(&:id).sort).to eq(tags.collect(&:id).sort)
      expect(rows.flatten.count).to be(20)
    end

    it 'returns the correct rows when there are 24 tags' do
      tags = create_tags(24)
      formatter = HoneycombChartFormatter.new(tags.dup)
      rows = formatter.format_rows!
      expect(rows[0].count).to be(3)
      expect(rows[1].count).to be(4)
      expect(rows[2].count).to be(5)
      expect(rows[3].count).to be(6)
      expect(rows[4].count).to be(5)
      expect(rows[5].count).to be(1)
      expect(rows[6]).to be(nil)
      expect(rows.flatten.collect(&:id).sort).to eq(tags.collect(&:id).sort)
      expect(rows.flatten.count).to be(24)
    end

    it 'returns the correct rows when there are 30 tags' do
      tags = create_tags(30)
      formatter = HoneycombChartFormatter.new(tags.dup)
      rows = formatter.format_rows!
      expect(rows[0].count).to be(3)
      expect(rows[1].count).to be(4)
      expect(rows[2].count).to be(5)
      expect(rows[3].count).to be(6)
      expect(rows[4].count).to be(5)
      expect(rows[5].count).to be(4)
      expect(rows[6].count).to be(3)
      expect(rows[7]).to be(nil)
      expect(rows.flatten.collect(&:id).sort).to eq(tags.collect(&:id).sort)
      expect(rows.flatten.count).to be(30)
    end

    it 'returns the correct rows when there are 31 tags' do
      tags = create_tags(31)
      formatter = HoneycombChartFormatter.new(tags.dup)
      rows = formatter.format_rows!
      expect(rows[0].count).to be(3)
      expect(rows[1].count).to be(4)
      expect(rows[2].count).to be(5)
      expect(rows[3].count).to be(6)
      expect(rows[4].count).to be(5)
      expect(rows[5].count).to be(4)
      expect(rows[6].count).to be(3)
      expect(rows[7].count).to be(1)
      expect(rows[8]).to be(nil)
      expect(rows.flatten.collect(&:id).sort).to eq(tags.collect(&:id).sort)
      expect(rows.flatten.count).to be(31)
    end

    it 'returns the correct rows when there are 40 tags' do
      tags = create_tags(40)
      formatter = HoneycombChartFormatter.new(tags.dup)
      rows = formatter.format_rows!
      expect(rows[0].count).to be(5)
      expect(rows[1].count).to be(6)
      expect(rows[2].count).to be(7)
      expect(rows[3].count).to be(8)
      expect(rows[4].count).to be(7)
      expect(rows[5].count).to be(6)
      expect(rows[6].count).to be(1)
      expect(rows.flatten.collect(&:id).sort).to eq(tags.collect(&:id).sort)
      expect(rows.flatten.count).to be(40)
    end
  end
end