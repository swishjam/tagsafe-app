class TagsafeAws
  class S3
    class << self
      def client
        @_client ||= Aws::S3::Client.new(region: 'us-east-1')
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
        client.invoke(
          function_name: function_name,
          invocation_type: async ? 'Event' : 'RequestResponse',
          log_type: 'Tail',
          payload: JSON.generate(payload)
        )
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
        client(region).disable_rule(name: name, event_bus_name: event_bus_name)
      end

      def enable_rule(name, region:, event_bus_name: 'default')
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