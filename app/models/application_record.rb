class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # allows us to use .send dynamically using many methods
  def self.send_chain(methods)
    methods.inject(self) { |result, method| 
      result.send(*method) 
    }
  end
end
