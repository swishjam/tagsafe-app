class TagEvent < ApplicationRecord
  belongs_to :tag
  belongs_to :url_crawl

  acts_as_paranoid
end