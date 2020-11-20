module ActiveSupport
  class TimeWithZone
    def formatted
      strftime("%A, %B %d @ %I:%M %p (%Z)")
    end

    def formatted_short
      strftime("%m/%d/%y %l:%M %P %Z")
    end
  end
end