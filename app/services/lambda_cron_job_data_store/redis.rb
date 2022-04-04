module LambdaCronJobDataStore
  class Redis
    class << self
      def client
        @client ||= ::Redis.new(url: ENV['LAMBDA_CRON_JOB_DATA_STORE_REDIS_URL'])
      end

      def disconnect!
        client.disconnect!
        @client = nil
      end
    end
  end
end