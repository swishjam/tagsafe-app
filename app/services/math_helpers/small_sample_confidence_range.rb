module MathHelpers
  class SmallSampleConfidenceRange
    def initialize(data_points, confidence_percent = 95)
      @data_points = data_points
      @confidence_percent = confidence_percent
    end

    def range(round = true)
      "#{low_end(round)} - #{high_end(round)}"
    end

    def plus_minus(round = true)
      @plus_minus ||= (approximated_std_dev * num_std_deviations_for_confidence_level).round(round ? 3 : 20)
    end

    def mean
      @mean ||= MathHelpers::Statistics.mean(@data_points)
    end

    def low_end(round = true)
      @low_end ||= (mean - plus_minus).round(round ? 3 : 20)
    end

    def high_end(round = true)
      @high_end ||= (mean + plus_minus).round(round ? 3 : 20)
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
          2.0860,
          2.0796,
          2.0739,
          2.0686,
          2.0639,
          2.0596,
          2.0555,
          2.0518,
          2.0484,
          2.0452,
          2.0423
        ]
      }
    end
  end
end

# https://www.tdistributiontable.com/
# https://www.tutorialspoint.com/statistics/t_distribution_table.htm
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
# 21         1.7207  	2.0796  	2.5176  	2.8314
# 22         1.7172  	2.0739  	2.5083  	2.8188
# 23         1.7139  	2.0686  	2.4998  	2.8073
# 24         1.7109  	2.0639  	2.4922  	2.7970
# 25         1.7081  	2.0596  	2.4851  	2.7874
# 26         1.7056  	2.0555  	2.4786  	2.7787
# 27         1.7033  	2.0518  	2.4727  	2.7707
# 28         1.7011  	2.0484  	2.4671  	2.7633
# 29         1.6991  	2.0452  	2.4620  	2.7564
# 30         1.6973  	2.0423  	2.4572  	2.7500
# 31         1.6955  	2.0395  	2.4528  	2.7440
# 32         1.6939  	2.0369  	2.4487  	2.7385
# 33         1.6924  	2.0345  	2.4448  	2.7333
# 34         1.6909  	2.0322  	2.4411  	2.7284
# 35         1.6896  	2.0301  	2.4377  	2.7238
# 36         1.6883  	2.0281  	2.4345  	2.7195
# 37         1.6871  	2.0262  	2.4315  	2.7154
# 38         1.6859  	2.0244  	2.4286  	2.7115
# 39         1.6849  	2.0227  	2.4258  	2.7079
# 40         1.6839  	2.0211  	2.4233  	2.7045