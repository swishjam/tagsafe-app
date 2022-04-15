module LambdaCronJobDataStore
  class TagCheckIntervals
    REDIS_ROOT_KEY = 'tag_check_region_intervals'.freeze

    def initialize(tag)
      @tag = tag
    end

    def self.get_configuration_for_region(aws_region_name)
      JSON.parse(LambdaCronJobDataStore::Redis.client.get("#{REDIS_ROOT_KEY}:#{aws_region_name}") || '{}')
    end

    def sync!
      start = Time.now
      remove_tag_from_every_tag_check_region
      add_interval_for_all_of_tags_tag_check_regions(@tag.tag_preferences.tag_check_minute_interval) unless @tag.release_monitoring_disabled?
      Rails.logger.info "Updated Tag #{@tag.uid}'s TagCheckIntervals across all regions in #{Time.now - start} seconds"
    end

    def add_tags_current_interval_to_tag_check_region(tag_check_region)
      return if @tag.release_monitoring_disabled?
      intervals_config_for_region = self.class.get_configuration_for_region(tag_check_region.aws_region_name)
      intervals_config_for_region[@tag.tag_preferences.tag_check_minute_interval.to_s] ||= {}
      intervals_config_for_region[@tag.tag_preferences.tag_check_minute_interval.to_s][@tag.id.to_s] = true
      set_regions_tag_check_interval_configs(tag_check_region.aws_region_name, intervals_config_for_region)
    end

    def remove_tags_current_interval_from_tag_check_region(tag_check_region)
      intervals_config_for_region = self.class.get_configuration_for_region(tag_check_region.aws_region_name)
      return unless intervals_config_for_region[@tag.tag_preferences.tag_check_minute_interval.to_s].present?
      intervals_config_for_region[@tag.tag_preferences.tag_check_minute_interval.to_s].delete(@tag.id.to_s)
      set_regions_tag_check_interval_configs(tag_check_region.aws_region_name, intervals_config_for_region)
    end

    def add_interval_for_all_of_tags_tag_check_regions(interval)
      return if interval.nil?
      @tag.tag_check_regions.each do |tag_check_region|
        intervals_config_for_region = self.class.get_configuration_for_region(tag_check_region.aws_region_name)
        intervals_config_for_region[interval.to_s] ||= {}
        intervals_config_for_region[interval.to_s][@tag.id.to_s] = true
        set_regions_tag_check_interval_configs(tag_check_region.aws_region_name, intervals_config_for_region)
      end
    end

    def remove_interval_for_all_of_tags_tag_check_regions(interval)
      return if interval.nil?
      @tag.tag_check_regions.each do |tag_check_region|
        intervals_config_for_region = self.class.get_configuration_for_region(tag_check_region.aws_region_name)
        return unless intervals_config_for_region[interval.to_s].present?
        intervals_config_for_region[interval.to_s].delete(@tag.id.to_s)
        set_regions_tag_check_interval_configs(tag_check_region.aws_region_name, intervals_config_for_region)
      end
    end

    def self.remove_tag_id_from_every_tag_check_region(tag_id)
      TagCheckRegion.REGION_NAMES.each do |aws_region_name|
        regions_intervals_config = get_configuration_for_region(aws_region_name)
        regions_intervals_config.keys.each do |interval|
          regions_interval_config = regions_intervals_config[interval.to_s] || {}
          next unless regions_interval_config[tag_id.to_s].present?
          regions_interval_config.delete(tag_id.to_s)
          break
        end
        set_regions_tag_check_interval_configs(aws_region_name, regions_intervals_config)
      end
    end

    private

    def self.set_regions_tag_check_interval_configs(aws_region_name, region_intervals)
      LambdaCronJobDataStore::Redis.client.set("#{REDIS_ROOT_KEY}:#{aws_region_name}", region_intervals.to_json)
    end

    def set_regions_tag_check_interval_configs(aws_region_name, region_intervals)
      self.class.set_regions_tag_check_interval_configs(aws_region_name, region_intervals)
    end
  end
end


# Redis Key: aws_region_name (us-east-1)
# {
#   1: {
#      800: true,
#      728: true,
#       ....
#   }
# }