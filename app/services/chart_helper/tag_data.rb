module ChartHelper
  class TagData < Base
    attr_reader :start_datetime, :min_plot_point, :max_plot_point
    
    def initialize(tag:, time_range:)
      @tag = tag
      @start_datetime = derived_start_time_from_time_range(time_range.to_sym)
      
      @min_plot_point = nil
      @max_plot_point = nil

      chart_data
    end
  
    def chart_data
      Rails.cache.fetch(cache_key, expires_in: 1.minute) { formatted_chart_data! }
    end

    def graph_zone_data(depth: 300)
      graph_zone_data = chart_data[0][:data].map do |timestamp, tagsafe_score| 
        { 
          value: (timestamp.to_f * 1_000).floor, 
          color: tagsafe_score >= 90 ? 'green' : tagsafe_score >= 80 ? 'orange' : 'red',
          fillColor: {
            linearGradient: [0, 0, 0, depth],
            stops: tagsafe_score >= 90 ? [
              [0, 'lightgreen'],
              [0.5, 'rgb(200, 255, 200)'],
              [1, 'white']
            ] : tagsafe_score >= 80 ? [
              [0, '#fb9c5e26'],
              [0.5, 'rgb(255, 240, 213)'],
              [1, 'white']
            ] : [
              [0, '#fb5e5e29'],
              [0.5, 'rgb(255, 212, 212)'],
              [1, 'white']
            ]
          }
        }
      end.sort_by{ |h| h[:value] }
      graph_zone_data << graph_zone_data.last.except(:value) unless graph_zone_data.empty?
      graph_zone_data
    end

    private

    def formatted_chart_data!
      @formatted_chart_data ||= begin
        Rails.logger.info "ChartHelper::TagsData Cache miss for #{cache_key}"
        add_all_audits_since_start_datetime
        add_synthetic_plot_points_for_timestamps_between_audits
        add_starting_and_current_datetime_plot_if_necessary
        [{ name: 'Tagsafe Score', data: map_plot_points_into_formatted_chart_data }]
      end
    end

    def cache_key
      "charts:#{@tag.uid}_Tagsafe_Score_#{@start_datetime.beginning_of_minute}"
    end

    def map_plot_points_into_formatted_chart_data
      formatted_chart_data = []
      current_plot_point = @min_plot_point
      while current_plot_point
        formatted_chart_data << current_plot_point.formatted_for_chart_data
        current_plot_point = current_plot_point.next_plot_point
      end
      formatted_chart_data
    end

    def add_all_audits_since_start_datetime
      # THE ORDER MATTERS HERE, `more_recent_than` scopes apply an order by clause :/
      @tag.audits
            .successful
            .most_recent_last
            .more_recent_than_or_equal_to(@start_datetime)
            .each do |audit|
        audits_plot_point = PlotPoint.new(
          timestamp: audit.created_at, 
          value: audit.tagsafe_score,
          previous_plot_point: @max_plot_point,
          next_plot_point: nil,
          is_synthetic: false
        )

        @max_plot_point.next_plot_point = audits_plot_point unless @max_plot_point.nil?
        @min_plot_point = audits_plot_point if @min_plot_point.nil?
        @max_plot_point = audits_plot_point
      end
    end

    def add_synthetic_plot_points_for_timestamps_between_audits
      current_plot_point = @min_plot_point
      while current_plot_point && current_plot_point.next_plot_point
        synthetic_plot_point = PlotPoint.new(
          timestamp: current_plot_point.next_plot_point.timestamp - 1.minute,
          value: current_plot_point.value,
          next_plot_point: current_plot_point.next_plot_point,
          previous_plot_point: current_plot_point,
          is_synthetic: true
        )
        current_plot_point.next_plot_point.previous_plot_point = synthetic_plot_point
        current_plot_point.next_plot_point = synthetic_plot_point
        current_plot_point = synthetic_plot_point.next_plot_point
      end
    end

    def add_starting_and_current_datetime_plot_if_necessary
      # if @chart_data[:data].any?
      if @min_plot_point.present?
        add_starting_and_current_datetime_plot_for_tag_that_has_chart_data
      else
        add_starting_and_current_datetime_plot_for_tag_that_doesnt_have_any_chart_data
      end
    end

    def add_starting_and_current_datetime_plot_for_tag_that_has_chart_data
      plot_point_for_current_timestamp = PlotPoint.new(
        timestamp: Time.current,
        value: @max_plot_point.value,
        previous_plot_point: @max_plot_point,
        next_plot_point: nil,
        is_synthetic: true
      )
      @max_plot_point.next_plot_point = plot_point_for_current_timestamp
      @max_plot_point = plot_point_for_current_timestamp

      return if @min_plot_point.timestamp - @start_datetime <= 1.minute
      most_recent_audit_before_starting_datetime = @tag.audits
                                                        .most_recent_first
                                                        .successful
                                                        .older_than(@min_plot_point.timestamp)
                                                        .limit(1).first
      # dont add the starting timestamp for this tag if the earliest audit in the 
      # chart was the first audit performed against this tag.
      unless most_recent_audit_before_starting_datetime.nil?
        synthetic_plot_point_for_timestamp_just_older_than_oldest_audit_within_range = PlotPoint.new(
          timestamp: @min_plot_point.timestamp - 1.minute < @start_datetime ? @start_datetime : @min_plot_point.timestamp - 1.minute,
          value: most_recent_audit_before_starting_datetime.tagsafe_score,
          next_plot_point: @min_plot_point,
          previous_plot_point: nil,
          is_synthetic: true
        )

        synthetic_plot_point_for_start_datetime = PlotPoint.new(
          timestamp: @start_datetime,
          value: most_recent_audit_before_starting_datetime.tagsafe_score,
          next_plot_point: synthetic_plot_point_for_timestamp_just_older_than_oldest_audit_within_range,
          previous_plot_point: nil,
          is_synthetic: true
        )

        @min_plot_point.previous_plot_point = synthetic_plot_point_for_timestamp_just_older_than_oldest_audit_within_range

        synthetic_plot_point_for_timestamp_just_older_than_oldest_audit_within_range.previous_plot_point = synthetic_plot_point_for_start_datetime
        @min_plot_point = synthetic_plot_point_for_start_datetime
      end
    end

    def add_starting_and_current_datetime_plot_for_tag_that_doesnt_have_any_chart_data
      return if @tag.most_current_audit.nil?
      first_timestamp = @tag.most_current_audit.created_at < @start_datetime ? @start_datetime : @tag.most_current_audit.created_at
      tagsafe_score = @tag.most_current_audit.tagsafe_score
      
      @min_plot_point = PlotPoint.new(
        timestamp: first_timestamp,
        value: tagsafe_score,
        previous_plot_point: nil,
        next_plot_point: nil,
        is_synthetic: true
      )

      @max_plot_point = PlotPoint.new(
        timestamp: Time.current,
        value: tagsafe_score,
        previous_plot_point: @min_plot_point,
        next_plot_point: nil,
        is_synthetic: true
      )

      @min_plot_point.next_plot_point = @max_plot_point
    end
  end
end