class TagsafeS3
  class << self
    def client
      @_client ||= Aws::S3::Client.new(
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
        region: 'us-east-1'
      )
    end

    def get_object_by_s3_url(s3_url)
      client.get_object({ bucket: url_to_bucket(s3_url), key: url_to_key(s3_url) })
    end

    def delete_object_by_s3_url(s3_url)
      client.delete_object({ bucket: url_to_bucket(s3_url), key: url_to_key(s3_url) })
    end

    def url_to_bucket(s3_url)
      URI.parse(s3_url).hostname.split('.')[0]
    end

    def url_to_key(s3_url)
      URI.parse(s3_url).path.gsub('/', '')
    end
  end
end