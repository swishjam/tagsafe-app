module LambdaCronJobDataStore
  class TagCheckIntervals
    REDIS_ROOT_KEY = 'tag_check_region_intervals'.freeze

    def initialize(tag)
      @tag = tag
    end

    def add_current_tag_check_interval_configuration_to_tag_check_region(tag_check_region)
      region_intervals = get_tag_check_intervals_json_for_region(tag_check_region.aws_region_name)
      region_intervals[@tag.tag_preferences.tag_check_minute_interval.to_s] ||= {}
      region_intervals[@tag.tag_preferences.tag_check_minute_interval.to_s][@tag.id.to_s] = true
      set_regions_tag_check_interval_configs(tag_check_region.aws_region_name, region_intervals)
    end
    
    def remove_current_tag_check_interval_configuration_from_tag_check_region(tag_check_region)
      region_intervals = get_tag_check_intervals_json_for_region(tag_check_region.aws_region_name)
      return if region_intervals[@tag.tag_preferences.tag_check_minute_interval.to_s].nil?
      region_intervals[@tag.tag_preferences.tag_check_minute_interval.to_s].delete(@tag.id.to_s)
      set_regions_tag_check_interval_configs(tag_check_region.aws_region_name, region_intervals)
    end

    def remove_specific_tag_check_interval_from_all_tags_tag_check_regions(interval)
      @tag.tag_check_regions.each do |tag_check_region|
        remove_tag_check_interval_configuration_from_tag_check_region(interval, tag_check_region)
      end
    end

    def remove_current_tag_check_interval_configuration_from_all_tags_tag_check_regions
      remove_specific_tag_check_interval_from_all_tags_tag_check_regions(@tag.tag_preferences.tag_check_minute_interval)
    end

    def sync_current_tag_check_interval_for_tags_tag_check_regions
      remove_tag_entirely_from_all_regions
      return if @tag.release_monitoring_disabled?
      set_tag_check_intervals_for_tags_current_tag_check_regions
    end

    def set_tag_check_intervals_for_tags_current_tag_check_regions
      @tag.tag_check_regions.each do |tag_check_region|
        add_current_tag_check_interval_configuration_to_tag_check_region(tag_check_region)
      end
    end

    def remove_tag_tag_check_configuration_from_tags_current_tag_check_regions
      @tag.tag_check_regions.each do |tag_check_region|
        remove_tag_from_tag_check_region(tag_check_region.aws_region_name)
      end
    end

    private

    def set_regions_tag_check_interval_configs(aws_region_name, region_intervals)
      LambdaCronJobDataStore::Redis.client.set("#{REDIS_ROOT_KEY}:#{aws_region_name}", region_intervals.to_json)
    end

    def get_tag_check_intervals_json_for_region(aws_region_name)
      JSON.parse(LambdaCronJobDataStore::Redis.client.get("#{REDIS_ROOT_KEY}:#{aws_region_name}") || '{}')
    end

    def remove_tag_from_tag_check_region(aws_region_name)
      regions_tag_check_intervals = get_tag_check_intervals_json_for_region(aws_region_name)
      regions_tag_check_intervals.delete(@tag.id.to_s)
      set_regions_tag_check_interval_configs(aws_region_name, regions_tag_check_intervals)
    end

    def remove_tag_entirely_from_all_regions
      TagCheckRegion.REGION_NAMES.each do |aws_region_name|
        regions_intervals_config = get_tag_check_intervals_json_for_region(aws_region_name)
        regions_intervals_config.keys.each do |interval|
          regions_interval_config = regions_intervals_config[interval.to_s] || {}
          next unless regions_interval_config[@tag.id.to_s].present?
          regions_interval_config.delete(@tag.id.to_s)
          break
        end
        set_regions_tag_check_interval_configs(aws_region_name, regions_intervals_config)
      end
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