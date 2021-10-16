class MockWebsiteModerator
  class TooManyRedirects < StandardError; end;
  BUCKET_NAME_PREFIX = "#{Rails.env.development? ? 'dev' : 'prod'}-mock-site"

  attr_accessor :s3_website_url

  def initialize(page_url)
    @page_url = page_url
    @s3_website_url = "http://#{bucket_name}.s3-website-us-east-1.amazonaws.com"
  end

  def create_mock_website_for_url
    create_bucket
    set_bucket_to_website_hosting
    upload_page_html_to_bucket
  end

  private

  def create_bucket
    s3_client.create_bucket({
      bucket: bucket_name,
      acl: 'public-read'
    })
  end

  def set_bucket_to_website_hosting
    s3_client.put_bucket_website({
      bucket: bucket_name,
      website_configuration: {
        index_document: {
          suffix: 'index.html'
        }
      }
    })
  end

  def upload_page_html_to_bucket
    html = get_html_content(@page_url)
    modified_html = html_with_relative_path_assets_as_full_path(html)
    upload_content_to_bucket_index_file(modified_html)
  end

  def get_html_content(url, attempt_number: 1)
    raise TooManyRedirects, "#{url} request redirected the maximum 10 times." if attempt_number > 10
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    resp = http.get(uri.request_uri, { 'User-Agent' => "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" })
    case resp.class.to_s
    when 'Net::HTTPOK'
      resp.body
    when 'Net::HTTPMovedPermanently'
      get_html_content(resp['location'], attempt_number: attempt_number+1)
    else
      resp.error!
    end
  end

  def html_with_relative_path_assets_as_full_path(html)
    dom = Nokogiri::HTML::DocumentFragment.parse(html)
    potential_relative_path_scripts = dom.css("script[src^='/']")
    potential_relative_path_styles = dom.css("link[href^='/']")

    potential_relative_path_scripts.each do |script|
      if script['src'][1] != '/'
        full_path = "#{parsed_url.scheme}://#{parsed_url.host}#{script['src']}"
        puts "Updating mock website #{@page_url} script src #{script['src']} to #{full_path}"
        script['src'] = full_path
      end
    end
    
    potential_relative_path_styles.each do |link|
      if link['href'][1] != '/'
        full_path = "#{parsed_url.scheme}://#{parsed_url.host}#{link['href']}"
        puts "Updating mock website #{@page_url} link href #{link['href']} to #{full_path}"
        link['href'] = full_path
      end
    end

    dom.to_html
  end

  def upload_content_to_bucket_index_file(content)
    s3_client.put_object({
      acl: 'public-read',
      body: content,
      bucket: bucket_name,
      key: 'index.html'
    })
  end

  def bucket_name
    [BUCKET_NAME_PREFIX, sanitized_page_url].join('-')
  end

  def parsed_url
    @parsed_url ||= URI(@page_url)
  end
  
  def sanitized_page_url
    "#{parsed_url.host}#{parsed_url.path}".gsub(/:|\/|\./, '-')
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: 'us-east-1'
    )
  end
end