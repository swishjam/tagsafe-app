module ChartHelper
  class PlotPoint
    attr_accessor :timestamp, :value, :next_plot_point, :previous_plot_point, :is_synthetic

    def initialize(timestamp:, value:, next_plot_point:, previous_plot_point:, is_synthetic:)
      @timestamp = timestamp
      @value = value
      @next_plot_point = next_plot_point
      @next_plot_point = next_plot_point
    end

    def formatted_for_chart_data
      [@timestamp, @value]
    end

    def <=>(other_plot_point)
      timestamp <=> other_plot_point.timestamp
    end
  end
end