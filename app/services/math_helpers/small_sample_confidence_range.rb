module MathHelpers
  class SmallSampleConfidenceRange
    def initialize(data_points, confidence_percent = 95)
      @data_points = data_points
      @confidence_percent = confidence_percent
    end

    def range
      "#{low_end} - #{high_end}"
    end

    def plus_minus
      @plus_minus ||= approximated_std_dev * num_std_deviations_for_confidence_level
    end

    def low_end
      @low_end ||= mean - plus_minus
    end

    def high_end
      @high_end ||= mean + plus_minus
    end

    private

    def num_std_deviations_for_confidence_level
      # make it 0 index, and n - 1 for sample size
      @num_std_deviations_for_confidence_level ||= self.class.T_TABLE[@confidence_percent][@data_points.count - 2]
    end

    def approximated_std_dev
      @approximated_std_dev ||= sample_std_dev / Math.sqrt(@data_points.count)
    end

    def sample_std_dev
      @sample_std_dev ||= MathHelpers::Statistics.std_dev(@data_points, sample: true)
    end

    def mean
      @mean ||= MathHelpers::Statistics.mean(@data_points)
    end

    def self.T_TABLE
      {
        95 => [
          12.7065,
          4.3026, 
          3.1824, 
          2.7764, 
          2.5706, 
          2.4469, 
          2.3646, 
          2.3060, 
          2.2621, 
          2.2282, 
          2.2010, 
          2.1788, 
          2.1604, 
          2.1448, 
          2.1314, 
          2.1199, 
          2.1098, 
          2.1009, 
          2.0930, 
          2.0860
        ]
      }
    end
  end
end


# One Tail	 0.05	    0.025 	  0.01    	0.005
# Two Tails	 0.1	    0.05    	0.02    	0.01
# Sample Size
# 1	         6.3138	  12.7065	  31.8193	  63.6551
# 2        	 2.9200	  4.3026	  6.9646	  9.9247
# 3	         2.3534	  3.1824	  4.5407	  5.8408
# 4	         2.1319	  2.7764	  3.7470	  4.6041
# 5	         2.0150	  2.5706	  3.3650	  4.0322
# 6	         1.9432	  2.4469	  3.1426	  3.7074
# 7	         1.8946	  2.3646	  2.9980	  3.4995
# 8	         1.8595	  2.3060	  2.8965	  3.3554
# 9	         1.8331	  2.2621	  2.8214	  3.2498
# 10	       1.8124	  2.2282	  2.7638	  3.1693
# 11	       1.7959	  2.2010	  2.7181	  3.1058
# 12	       1.7823	  2.1788	  2.6810	  3.0545
# 13	       1.7709	  2.1604	  2.6503	  3.0123
# 14	       1.7613	  2.1448	  2.6245	  2.9768
# 15	       1.7530	  2.1314	  2.6025	  2.9467
# 16	       1.7459	  2.1199	  2.5835	  2.9208
# 17	       1.7396	  2.1098	  2.5669	  2.8983
# 18	       1.7341	  2.1009	  2.5524	  2.8784
# 19	       1.7291	  2.0930	  2.5395	  2.8609
# 20	       1.7247	  2.0860	  2.5280	  2.8454