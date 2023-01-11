class HtmlElement < ApplicationRecord
  belongs_to :tag_snippet
  has_many :html_element_attributes

  has_one_attached :inner_text
end