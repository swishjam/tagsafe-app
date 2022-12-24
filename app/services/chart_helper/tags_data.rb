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
      add_all_audits_since_start_datetime
      add_starting_and_current_datetime_plot_if_necessary
      @chart_data.values
    end

    def tag_ids
      @tag_ids ||= @tags.collect(&:id)
    end

    def cache_key
      "charts:#{tag_ids.join('-')}_#{@metric_key}_#{@start_datetime.beginning_of_minute}"
    end

    def add_all_audits_since_start_datetime
      Audit.includes(:tag, :tag_version)
              .where(tag_id: tag_ids)
              .successful
              .more_recent_than_or_equal_to(@start_datetime, timestamp_column: 'audits.created_at')
              .order('audits.created_at ASC')
              .group_by{ |audit| audit.tag }.each do |tag, audits|
        chart_data_for_tag = audits.collect{ |audit| [audit.created_at, audit.tagsafe_score] }
        @chart_data[tag] = @chart_data[tag] || { name: @use_metric_key_as_plot_name ? 'Tagsafe Score' : tag.try_friendly_name, data: [] }
        @chart_data[tag][:data].concat(chart_data_for_tag)
      end
    end

    def add_starting_and_current_datetime_plot_if_necessary
      @tags.each do |tag|
        @chart_data[tag] = @chart_data[tag] || { name: @use_metric_key_as_plot_name ? 'Tagsafe Score' : tag.try_friendly_name, data: [] }
        if @chart_data[tag][:data].any?
          add_starting_and_current_datetime_plot_for_tag_that_has_chart_data(tag)
        else
          add_starting_and_current_datetime_plot_for_tag_that_doesnt_have_any_chart_data(tag)
        end
      end
    end

    def add_starting_and_current_datetime_plot_for_tag_that_has_chart_data(tag)
      @chart_data[tag][:data].prepend([ Time.current, @chart_data[tag][:data].first[1] ])
      earliest_audit_timestamp_for_tag_in_chart = @chart_data[tag][:data].last[0]
      most_recent_audit_before_starting_datetime = tag.audits
                                                        .most_recent_first
                                                        .older_than(earliest_audit_timestamp_for_tag_in_chart)
                                                        .limit(1).first
      # dont add the starting timestamp for this tag if the earliest audit in the 
      # chart was the first audit performed against this tag.
      unless most_recent_audit_before_starting_datetime.nil?
        @chart_data[tag][:data] << [@start_datetime, most_recent_audit_before_starting_datetime.tagsafe_score]
      end
    end

    def add_starting_and_current_datetime_plot_for_tag_that_doesnt_have_any_chart_data(tag)
      return if tag.most_current_audit.nil?
      first_timestamp = tag.most_current_audit.created_at < @start_datetime ? @start_datetime : tag.most_current_audit.created_at
      metric = tag.most_current_audit.tagsafe_score
      @chart_data[tag][:data] = [ 
        [Time.current, metric],
        [first_timestamp, metric]
      ]
    end
  end
end