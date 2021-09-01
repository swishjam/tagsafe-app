module Statistics
  class << self
    def std_dev(data)
      Math.sqrt(variance(data))
    end

    def variance(data)
      mean = mean(data)
      squared_diff = data.map{ |result| (mean - result) ** 2 }
      mean(squared_diff)
    end

    def mean(data)
      data.sum / data.size
    end
  end
end