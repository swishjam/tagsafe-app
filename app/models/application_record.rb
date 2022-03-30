class ApplicationRecord < ActiveRecord::Base
  include ContextualUid
  self.abstract_class = true

  scope :older_than, -> (timestamp, timestamp_column: :created_at) { where("#{timestamp_column} < ?", timestamp).order("#{timestamp_column.to_s} DESC") }
  scope :older_than_or_equal_to, -> (timestamp, timestamp_column: :created_at) { where("#{timestamp_column} <= ?", timestamp).order("#{timestamp_column.to_s} DESC") }
 
  scope :more_recent_than, -> (timestamp, timestamp_column: :created_at) { where("#{timestamp_column} > ?", timestamp).order("#{timestamp_column.to_s} DESC") }
  scope :more_recent_than_or_equal_to, -> (timestamp, timestamp_column: :created_at) { where("#{timestamp_column} >= ?", timestamp).order("#{timestamp_column.to_s} DESC") }

  scope :most_recent_first, -> (timestamp_column: :created_at) { order("#{timestamp_column} DESC") }
  scope :most_recent_last, -> (timestamp_column: :created_at) { order("#{timestamp_column} ASC") }
  
  def toggle_boolean_column(column)
    attrs = {}
    attrs[column] = !send(column)
    update(attrs)
  end

  def column_changed_to(column, value)
    saved_changes[column] && saved_changes[column][1] == value
  end

  class << self
    def destroy_all_fully!
      if column_names.include? 'deleted_at'
        all.each(&:destroy_fully!)
      else
        destroy_all
      end
    end

    def column_update_listener(*columns)
      columns.each do |column|
        define_singleton_method(:"after_#{column}_updated_to") do |expected_value, callback_method|
          after_update do
            if saved_changes[column.to_s] && (saved_changes[column.to_s][1] == expected_value || expected_value == nil)
              if block_given?
                yield self
                # self.class.instance_eval(&callback_block)
              elsif callback_method
                if callback_method.is_a?(Proc)
                  self.instance_eval(&callback_method)
                  # callback_method.call(self)
                elsif callback_method.is_a?(Symbol)
                  self.send(callback_method)
                end
              else
                raise StandardError, "A block or callback_method is required in the `after_#{column}` method"
              end
            end
          end
        end
        define_singleton_method(:"after_#{column}_updated", method(:"after_#{column}_updated_to"))
      end
    end

    # allows us to use .send dynamically using many methods
    def chain_scopes(methods)
      methods.inject(self) { |result, method| result.send(*method) }
    end
  end
end
