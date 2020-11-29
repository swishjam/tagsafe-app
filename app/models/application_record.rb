class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  scope :most_recent_first, -> (timestamp_column = 'created_at') { order("#{timestamp_column} DESC") }
  scope :most_recent_last, -> (timestamp_column = 'created_at') { order("#{timestamp_column} ASC") }

  class << self
    attr_accessor :skip_callbacks
    
    def without_callbacks(&block)
      self.skip_callbacks = true
      yield
      self.skip_callbacks = false
    end

    # allows us to use .send dynamically using many methods
    def send_chain(methods)
      methods.inject(self) { |result, method| 
        result.send(*method) 
      }
    end
  end
end
