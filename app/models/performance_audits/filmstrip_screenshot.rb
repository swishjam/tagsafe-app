class FilmstripScreenshot < ApplicationRecord
  belongs_to :performance_audit
  has_one_attached :image
end