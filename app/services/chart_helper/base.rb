module ChartHelper
  class Base
    def derived_start_time_from_time_range(time_range)
      {
        :"7_days" => (Time.current.beginning_of_day - 6.days),
        :"24_hours" => (Time.current - 24.hours),
        :"today" => (Time.current.beginning_of_day),
        :"12_hours" => (Time.current - 12.hours),
        :"6_hours" => (Time.current - 6.hours),
        :"60_minutes" => (Time.current - 60.minutes),
        :"1_hour" => (Time.current - 60.minutes),
        :"30_minutes" => (Time.current - 30.minutes)
      }[time_range] || begin 
        raise StandardError, "Invalid `time_range` passed to #{self.class.to_s}: #{time_range}"
      end
    end

    def chart_data
      raise StandardError, "Subclass #{self.class.to_s} must implement `chart_data` method."
    end
  end
end