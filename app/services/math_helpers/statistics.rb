module MathHelpers
  module Statistics
    class << self
      def std_dev(data, sample: false)
        Math.sqrt(variance(data, sample))
      end

      def variance(data, sample = false)
        mean = mean(data)
        squared_diff = data.map{ |result| (mean - result) ** 2 }
        mean(squared_diff, sample)
      end

      def mean(data, sample = false)
        data.sum / (sample ? data.size - 1 : data.size)
      end

      def median(data)
        sorted_data = data.sort
        if data.count.even?
          larger_median_index = data.count / 2
          mean(sorted_data[larger_median_index - 1..larger_median_index])
        else
          sorted_data[data.count / 2]
        end
      end

      def z_score(val, data)
        _std_dev = std_dev(data)
        _mean = mean(data)
        (val - _mean) / _std_dev
      end
    end
  end
end