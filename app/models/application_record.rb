class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  scope :older_than, -> (timestamp, timestamp_column: :created_at) { where("#{timestamp_column} < ?", timestamp).order('created_at DESC') }
  scope :older_than_or_equal_to, -> (timestamp, timestamp_column: :created_at) { where("#{timestamp_column} <= ?", timestamp).order('created_at DESC') }
 
  scope :more_recent_than, -> (timestamp, timestamp_column: :created_at) { where("#{timestamp_column} > ?", timestamp).order('created_at DESC') }
  scope :more_recent_than_or_equal_to, -> (timestamp, timestamp_column: :created_at) { where("#{timestamp_column} >= ?", timestamp).order('created_at DESC') }

  scope :most_recent_first, -> (timestamp_column: :created_at) { order("#{timestamp_column} DESC") }
  scope :most_recent_last, -> (timestamp_column: :created_at) { order("#{timestamp_column} ASC") }
  
  def toggle_boolean_column(column)
    attrs = {}
    attrs[column] = !send(column)
    update(attrs)
  end

  class << self
    attr_accessor :skip_callbacks
    
    def without_callbacks(&block)
      self.skip_callbacks = true
      yield
      self.skip_callbacks = false
    end

    # allows us to use .send dynamically using many methods
    def chain_scopes(methods)
      methods.inject(self) { |result, method| 
        result.send(*method) 
      }
    end
  end
end
