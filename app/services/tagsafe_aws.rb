class TagsafeAws
  class S3
    class << self
      def client
        @_client ||= Aws::S3::Client.new(region: 'us-east-1')
      end

      def get_object_by_s3_url(s3_url)
        client.get_object(bucket: url_to_bucket(s3_url), key: url_to_key(s3_url))
      end

      def delete_object_by_s3_url(s3_url)
        client.delete_object(bucket: url_to_bucket(s3_url), key: url_to_key(s3_url))
      rescue => e
        puts "CANNOT DELETE #{s3_url}: #{e.message}"
      end

      def write_to_s3(bucket:, key:, content:, acl: nil, cache_control: nil, content_type: nil, include_md5: true)
        args = { bucket: bucket, key: key, body: content }
        args[:acl] = acl unless acl.nil?
        args[:cache_control] = cache_control unless cache_control.nil?
        args[:content_type] = content_type unless content_type.nil?
        args[:content_md5] = Digest::MD5.base64digest(content) if include_md5
        client.put_object(args)
      end

      def url_to_bucket(s3_url)
        URI.parse(s3_url).hostname.split('.')[0]
      end

      def url_to_key(s3_url)
        URI.parse(s3_url).path.gsub('/', '')
      end
    end
  end

  class CloudFront
    class << self
      def client
        @_client ||= Aws::CloudFront::Client.new(region: 'us-east-1')
      end

      def invalidate_cache(*paths)
        Rails.logger.info "TagsafeAws::Cloudfront -- Invaliding CloudFront cache for #{paths.join(', ')}."
        client.create_invalidation(
          distribution_id: ENV['TAGSAFE_INSTRUMENTATION_CLOUDFRONT_DISTRIBUTION_ID'],
          invalidation_batch: {
            paths: {
              quantity: 1,
              items: paths,
            },
            caller_reference: "#{Time.current.to_i}__#{paths.join('__')}"
          }
        )
      end
    end
  end

  class StateMachine
    class << self
      def client
        @_client ||= Aws::States::Client.new(region: 'us-east-1')
      end

      def execute(arn:, name:, input:)
        client.start_execution(
          state_machine_arn: arn,
          name: name,
          input: JSON.generate(input)
        )
      end

      def get_execution(execution_arn)
        client.describe_execution(execution_arn: execution_arn)
      end
    end
  end

  class Lambda
    class << self
      def client(http_read_timeout: 210)
        @_client ||= Aws::Lambda::Client.new(
          region: 'us-east-1',
          max_attempts: 1,
          retry_limit: 0,
          http_read_timeout: http_read_timeout
        )
      end

      def invoke_function(function_name:, payload:, async: true)
        resp = client.invoke(
          function_name: function_name,
          invocation_type: async ? 'Event' : 'RequestResponse',
          log_type: 'Tail',
          payload: JSON.generate(payload)
        )
        async ? resp : JSON.parse(resp.payload.string)
      end
    end
  end

  class EventBridge
    class << self
      def client(region)
        Aws::EventBridge::Client.new(region: region)
      end

      def list_rules(region:, event_bus_name: 'default')
        client(region).list_rules(event_bus_name: event_bus_name)
      end

      def get_rule(name, region:, event_bus_name: 'default')
        client(region).describe_rule(name: name, event_bus_name: event_bus_name)
      end

      def disable_rule(name, region:, event_bus_name: 'default')
        Rails.logger.info "TagsafeAws::EventBridge -- Disabling rule: #{name}, for event bus: #{event_bus_name}, in region: #{region}."
        client(region).disable_rule(name: name, event_bus_name: event_bus_name)
      end

      def enable_rule(name, region:, event_bus_name: 'default')
        Rails.logger.info "TagsafeAws::EventBridge -- Enabling rule: #{name}, for event bus: #{event_bus_name}, in region: #{region}."
        client(region).enable_rule(name: name, event_bus_name: event_bus_name)
      end
    end
  end

  # class SQS
  #   class << self
  #     def client 
  #       @_client ||= Aws::SQS::Client.new(
  #         access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  #         secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  #         region: 'us-east-1'
  #       )
  #     end

  #     def push_message_into_queue(queue_url:, message:)
  #       client.send_message({
  #         queue_url: queue_url,
  #         message_body: message
  #       })
  #     end
  #   end
  # end

  class CloudWatch
    class << self
      def client
        @_client ||= Aws::CloudWatchLogs::Client.new(region: 'us-east-1')
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