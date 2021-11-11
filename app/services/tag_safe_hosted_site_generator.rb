class TagSafeHostedSiteGenerator
  BUCKET_NAME_PREFIX = "#{Rails.env.development? ? 'dev' : 'prod'}-tsh"

  attr_accessor :s3_website_url

  def initialize(page_url)
    @page_url = page_url
    @s3_website_url = "http://#{bucket_name}.s3-website-us-east-1.amazonaws.com"
  end

  def generate_tagsafe_hosted_site
    create_bucket
    set_bucket_to_website_hosting
    upload_page_html_to_bucket
    s3_website_url
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
    html = get_content_from_url(@page_url)
    modified_html = update_pages_relative_assets_to_tagsafe_hosted_relative_files!(html)
    upload_content_to_s3_bucket(modified_html, 'index.html')
  end

  def get_content_from_url(url, attempt_number: 1)
    raise StandardError, "TagSafeHostedSiteGenerator error: #{url} request redirected the maximum 10 times." if attempt_number > 10
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    resp = http.get(uri.request_uri, { 'User-Agent' => "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" })
    case resp.class.to_s
    when 'Net::HTTPOK'
      resp.body
    when 'Net::HTTPMovedPermanently'
      get_content_from_url(resp['location'], attempt_number: attempt_number+1)
    else
      resp.error!
    end
  end

  def update_pages_relative_assets_to_tagsafe_hosted_relative_files!(page_html)
    dom = Nokogiri::HTML(page_html)
    
    potential_relative_path_scripts = dom.css("script[src^='/']")
    potential_relative_path_scripts.each do |script|
      if script['src'][1] != '/'
        full_path = "#{parsed_page_url.scheme}://#{parsed_page_url.host}#{script['src']}"
        puts "Uploading #{script['src']} script tag to TagSafe-hosted site."
        js_content = get_content_from_url(full_path)
        s3_file_path = script['src'].starts_with?('/') ? script['src'].slice(0) : script['src']
        upload_content_to_s3_bucket(js_content, s3_file_path)
      end
    end

    base_tag = dom.at("base") || Nokogiri::XML::Node.new('base', dom)
    base_tag['href'] = "#{parsed_page_url.scheme}://#{parsed_page_url.host}"
    dom.at('head').prepend_child(base_tag)
  
    dom.to_html
  end

  def upload_content_to_s3_bucket(content, file_name)
    s3_client.put_object({
      acl: 'public-read',
      body: content,
      bucket: bucket_name,
      key: file_name
    })
  end

  def bucket_name
    name = [BUCKET_NAME_PREFIX, sanitized_page_url].join('-')
    name.chomp!('-') if name.ends_with?('-')
    name
  end

  def parsed_page_url
    @parsed_page_url ||= URI(@page_url)
  end
  
  def sanitized_page_url
    "#{parsed_page_url.host}#{parsed_page_url.path}".gsub(/:|\/|\./, '-')
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: 'us-east-1'
    )
  end
end