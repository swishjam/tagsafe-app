module MathHelpers
  class OutlierHelper
    # [1, 1, 6, 13, 13, 14, 14, 14, 15, 15, 16, 18, 18, 18, 28]
    def initialize(data, sensitivity: :normal)
      @data = data
      @sensitivity = sensitivity
    end

    def find_outliers!
      @outliers ||= data_points_below_bottom_fence.concat(data_points_above_top_fence)
    end

    def bottom_fence
      # @bottom_fence ||= q1 - 1.5 * inter_quartile_range
      @bottom_fence ||= q1 - inter_quartile_multiplier * inter_quartile_range
    end

    def top_fence
      # @top_fence ||= q3 + 1.5 * inter_quartile_range
      @top_fence ||= q3 + inter_quartile_multiplier * inter_quartile_range
    end

    private

    def data_points_above_top_fence
      @data_points_above_top_fence ||= begin
        current_index = sorted_data.length - 1
        data_points = []
        while sorted_data[current_index] > top_fence
          data_point = sorted_data[current_index]
          data_points << data_point if data_point > top_fence
          current_index -= 1
        end
        data_points
      end
    end

    def data_points_below_bottom_fence
      @data_points_below_bottom_fence ||= begin
        current_index = 0
        data_points = []
        while sorted_data[current_index] < bottom_fence
          data_point = sorted_data[current_index]
          data_points << data_point if data_point < bottom_fence
          current_index += 1
        end
        data_points
      end
    end

    def inter_quartile_multiplier
      {
        high: 0.75,
        medium: 1,
        normal: 1.5,
        low: 1.75
      }[@sensitivity] || 1.5
    end

    def inter_quartile_range
      @inter_quartile_range ||= q3 - q1
    end

    def median
      @median ||= MathHelpers::Statistics.median(sorted_data)
    end

    def median_index
      @median_index ||= sorted_data.count / 2
    end

    def q1
      @q1 ||= MathHelpers::Statistics.median(sorted_data[0..median_index - 1])
    end

    def q3
      @q3 ||= MathHelpers::Statistics.median(sorted_data[median_index + 1..sorted_data.length])
    end

    def sorted_data
      @sorted_data ||= @data.sort
    end
  end
end