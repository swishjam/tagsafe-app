module HoneycombHelper
  class << self
    def bg_color_for(audit)
      case audit&.tagsafe_score
      when nil then 'lightgrey'
      when 0..35 then '#d60000'
      when 35..55 then '#d65200'
      when 55..60 then '#ef4800'
      when 60..65 then '#ef7000'
      when 65..70 then '#d67b00'
      when 70..75 then '#d6a100'
      when 75..80 then '#efc409'
      when 80..85 then '#d6d200'
      when 85..90 then '#93d600'
      when 90..100 then '#60cf60'
      when 95..100 then '#01e500'
      else nil
      end
    end
  end
end