module ChartHelper
  class TagsData < Base
    attr_reader :start_datetime
    
    def initialize(tags:, time_range:, metric_key:, use_metric_key_as_plot_name: false)
      @tags = tags
      @start_datetime = derived_start_time_from_time_range(time_range.to_sym)
      @metric_key = metric_key
      @use_metric_key_as_plot_name = use_metric_key_as_plot_name
      @chart_data = {}
      chart_data
    end
  
    def chart_data
      Rails.cache.fetch(cache_key, expires_in: 1.minute) { formatted_chart_data! }
    end

    def least_current_plot_point_for_tag(tag)
      @chart_data[tag][:data].last
    end
    alias oldest_plot_point_for_tag least_current_plot_point_for_tag

    def most_current_plot_point_for_tag(tag)
      @chart_data[tag][:data].first
    end

    def graph_zone_data
      graph_zone_data = chart_data[0][:data].map do |datetime, tagsafe_score| 
        { 
          value: (datetime.to_f * 1_000).round(0), 
          color: tagsafe_score >= 90 ? 'green' : tagsafe_score >= 80 ? 'orange' : 'red',
          fillColor: {
            linearGradient: [0, 0, 0, 300],
            stops: tagsafe_score >= 90 ? [
              [0, 'lightgreen'],
              [1, 'white']
            ] : tagsafe_score >= 80 ? [
              [0, '#fb9c5e26'],
              [1, 'white']
            ] : [
              [0, '#fb5e5e29'],
              [1, 'white']
            ]
          }
        }
      end.reverse
      graph_zone_data << graph_zone_data.last.except(:value)
    end

    private

    def formatted_chart_data!
      @formatted_chart_data ||= begin
        Rails.logger.info "ChartHelper::TagsData Cache miss for #{cache_key}"
        add_all_audits_since_start_datetime
        add_starting_and_current_datetime_plot_if_necessary
        @chart_data.values
      end
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
        chart_data_for_tag = []
        audits.each_with_index do |audit, i|
          datetime_of_previous_audit = chart_data_for_tag[i - 1] && chart_data_for_tag[i - 1][0]
          chart_data_for_tag << [datetime_of_previous_audit + 1.minute, audit.tagsafe_score] unless datetime_of_previous_audit.nil?
          chart_data_for_tag << [audit.created_at, audit.tagsafe_score]
        end
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
      return if @start_datetime - earliest_audit_timestamp_for_tag_in_chart <= 1.minute
      most_recent_audit_before_starting_datetime = tag.audits
                                                        .most_recent_first
                                                        .successful
                                                        .older_than(earliest_audit_timestamp_for_tag_in_chart)
                                                        .limit(1).first
      # dont add the starting timestamp for this tag if the earliest audit in the 
      # chart was the first audit performed against this tag.
      unless most_recent_audit_before_starting_datetime.nil?
        @chart_data[tag][:data] << [@start_datetime, most_recent_audit_before_starting_datetime.tagsafe_score]
        @chart_data[tag][:data] << [
          earliest_audit_timestamp_for_tag_in_chart - 1.minute < @start_datetime ? @start_datetime : earliest_audit_timestamp_for_tag_in_chart - 1.minute,
          most_recent_audit_before_starting_datetime.tagsafe_score
        ]
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