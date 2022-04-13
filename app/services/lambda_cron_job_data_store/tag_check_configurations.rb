module LambdaCronJobDataStore
  class TagCheckConfigurations
    REDIS_ROOT_KEY = 'tag_check_configurations'.freeze

    def initialize(tag)
      @tag = tag
    end

    def self.delete_tag_check_configuration_by_tag_id(tag_id)
      LambdaCronJobDataStore::Redis.client.del("#{REDIS_ROOT_KEY}:#{tag_id}")
    end

    def update_tag_check_configuration
      if @tag.release_monitoring_disabled?
        delete_tag_check_configuration
      else
        LambdaCronJobDataStore::Redis.client.set("#{REDIS_ROOT_KEY}:#{@tag.id}", constructed_tag_check_config.to_json)
      end
    end

    def delete_tag_check_configuration
      self.class.delete_tag_check_configuration_by_tag_id(@tag.id)
    end

    def current_tag_check_configuration
      LambdaCronJobDataStore::Redis.client.get("#{REDIS_ROOT_KEY}:#{@tag.id}")
    end

    private

    def constructed_tag_check_config
      {
        tag_id: @tag.id,
        tag_url: @tag.full_url,
        current_hashed_content: @tag.current_version&.hashed_content,
        recent_hashed_content: @tag.tag_versions.most_recent_first.limit(@tag.tag_or_domain_configuration.num_recent_tag_versions_to_compare_in_release_monitoring).collect(&:hashed_content),
        current_version_bytes_size: @tag.current_version&.bytes,
        num_recent_tag_versions_to_compare_in_release_monitoring: @tag.tag_or_domain_configuration.num_recent_tag_versions_to_compare_in_release_monitoring
      }
    end
  end
end