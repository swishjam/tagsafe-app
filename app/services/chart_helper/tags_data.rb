module ChartHelper
  class TagsData < Base
    def initialize(tags:, time_range:, metric_key:, use_metric_key_as_plot_name: false)
      @tags = tags
      @start_datetime = derived_start_time_from_time_range(time_range.to_sym)
      @metric_key = metric_key
      @use_metric_key_as_plot_name = use_metric_key_as_plot_name
      @chart_data = {}
    end
  
    def chart_data
      Rails.cache.fetch(cache_key, expires_in: 1.minute) { formatted_chart_data! }
    end

    private

    def formatted_chart_data!
      Rails.logger.info "ChartHelper::TagsData Cache miss for #{cache_key}"
      add_current_timestamp_to_chart_data
      add_all_audits_since_start_datetime
      add_starting_datetime_plot_if_necessary
      @chart_data.values
    end

    def tag_ids
      @tag_ids ||= @tags.collect(&:id)
    end

    def cache_key
      "#{tag_ids.join('-')}_#{@metric_key}_#{@start_datetime.beginning_of_minute}"
    end

    def add_current_timestamp_to_chart_data
      @tags.map do |tag|
        most_recent_audit = tag.most_recent_successful_audit
        unless most_recent_audit.nil?
          @chart_data[tag] = { 
            name: @use_metric_key_as_plot_name ? @metric_key.to_s.gsub('delta', '').strip.split('_').map(&:capitalize).join(' ') : tag.try_friendly_name, 
            data: [ [DateTime.now, most_recent_audit.preferred_delta_performance_audit[@metric_key]] ] 
          }
        end
      end
    end

    def add_all_audits_since_start_datetime
      AverageDeltaPerformanceAudit.includes(audit: [:tag, :tag_version])
                                    .where(audits: { tag_id: tag_ids })
                                    .more_recent_than_or_equal_to(@start_datetime, timestamp_column: 'audits.created_at')
                                    .order('audits.created_at ASC')
                                    .group_by{ |dpa| dpa.audit.tag }.each do |tag, delta_performance_audits|
        chart_data_for_tag = delta_performance_audits.collect{ |dpa| [dpa.audit.created_at, dpa[@metric_key]] }
        @chart_data[tag] = @chart_data[tag] || { name: tag.try_friendly_name, data: [] }
        @chart_data[tag][:data].concat(chart_data_for_tag)
      end
    end

    def add_starting_datetime_plot_if_necessary
      @chart_data.each do |tag, chart_data_hash|
        earliest_audit_timestamp_for_tag_in_chart = chart_data_hash[:data].last[0]
        most_recent_audit_before_starting_datetime = tag.audits.completed_performance_audit
                                                                .successful_performance_audit
                                                                .most_recent_first
                                                                .older_than(earliest_audit_timestamp_for_tag_in_chart)
                                                                .limit(1).first
        # dont add the starting timestamp for this tag if the earliest audit in the 
        # chart was the first audit performed against this tag.
        unless most_recent_audit_before_starting_datetime.nil?
          chart_data_hash[:data] << [@start_datetime, most_recent_audit_before_starting_datetime.preferred_delta_performance_audit[@metric_key]]
        end
      end
    end
  end
end