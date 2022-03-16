class TagsafeAws
  class S3
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

  class CloudWatch
    class << self
      def client
        @_client ||= Aws::CloudWatchLogs::Client.new(
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
          region: 'us-east-1'
        )
      end

      def get_log_events_in_stream(stream_name, log_group_name:)
        client.get_log_events({
          log_group_name: log_group_name,
          log_stream_name: stream_name,
          start_from_head: true,
          # start_time: enqueued_at.to_i,
          # end_time: completed_at.to_i
        }).events
      end

      def search_log_group_for_events(log_group_name, start_time: 1.day.ago, end_time: Time.now, filter_pattern: nil)
        client.filter_log_events({
          log_group_name: log_group_name,
          start_time: start_time.to_i * 1_000,
          end_time: end_time.to_i * 1_000,
          filter_pattern: filter_pattern
        }).events
      end
    end
  end
end