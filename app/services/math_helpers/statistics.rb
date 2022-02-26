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
    end
  end
end