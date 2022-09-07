class TagInjectPageUrlRule < ApplicationRecord
  belongs_to :tag

  def is_regex_pattern?
    is_regex_pattern
  end
end