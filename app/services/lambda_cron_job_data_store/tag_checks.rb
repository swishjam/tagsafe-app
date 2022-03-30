module LambdaCronJobDataStore
  class TagChecks
    REDIS_KEY = 'tag_check_configurations'.freeze

    def initialize(tag)
      @tag = tag
      @global_tag_check_config = previous_data_store_config_or_default_config
    end

    def self.current_config
      LambdaCronJobDataStore::Redis.client.get(REDIS_KEY)
    end

    def update_data_store_for_tag
      remove_previous_tag_check_config_from_previous_data_store_config
      update_previous_data_store_config_with_new_tag_check_config
      LambdaCronJobDataStore::Redis.client.set(REDIS_KEY, @global_tag_check_config.to_json)
      @global_tag_check_config
    end

    private

    def remove_previous_tag_check_config_from_previous_data_store_config
      TagPreference.SUPPORTED_TAG_CHECK_INTERVALS.each do |interval|
        tag_check_config = @global_tag_check_config[interval.to_s][@tag.id.to_s]
        next unless tag_check_config.present?
        @global_tag_check_config[interval.to_s].delete(@tag.id.to_s)
        break
      end
    end

    def update_previous_data_store_config_with_new_tag_check_config
      return if @tag.release_monitoring_disabled?
      @global_tag_check_config[@tag.tag_preferences.tag_check_minute_interval.to_s][@tag.id.to_s] = constructed_tag_check_config
    end

    def previous_data_store_config_or_default_config
      previous_config = self.class.current_config
      return JSON.parse(previous_config) unless previous_config.nil?
      JSON.parse(TagPreference.SUPPORTED_TAG_CHECK_INTERVALS.map{ |key| [key.to_s, {} ] }.to_h.to_json)
    end

    def constructed_tag_check_config
      {
        current_version_s3_url: @tag.current_version&.js_file&.url,
        current_hashed_content: @tag.current_version&.hashed_content,
        recent_hashed_content: @tag.tag_versions.most_recent_first.limit(5).collect(&:hashed_content),
        current_version_byte_size: @tag.current_version&.bytes
      }
    end
  end
end


# {
#   1: {
#     1251: { current_version_s3_url: 's3.aws.com/script.js' }
#   },
#   15: {
#     842: { current_version_s3_url: 's3.aws.com/script2.js' },
#     172: { current_version_s3_url: 's3.aws.com/script3.js' }
#   },
#   30: {
#   ....
# }