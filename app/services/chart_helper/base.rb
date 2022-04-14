module ChartHelper
  class Base
    def derived_start_time_from_time_range(time_range)
      {
        :"7_days" => (DateTime.now.beginning_of_day - 6.days),
        :"24_hours" => (DateTime.now - 24.hours),
        :"today" => (DateTime.now.beginning_of_day),
        :"12_hours" => (DateTime.now - 12.hours),
        :"6_hours" => (DateTime.now - 6.hours),
        :"60_minutes" => (DateTime.now - 60.minutes),
        :"1_hour" => (DateTime.now - 60.minutes),
        :"30_minutes" => (DateTime.now - 30.minutes)
      }[time_range] || begin 
        raise StandardError, "Invalid `time_range` passed to #{self.class.to_s}: #{time_range}"
      end
    end

    def chart_data
      raise StandardError, "Subclass #{self.class.to_s} must implement `chart_data` method."
    end
  end
end