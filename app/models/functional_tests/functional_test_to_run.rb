class FunctionalTestToRun < ApplicationRecord
  self.table_name = :functional_tests_to_run

  belongs_to :tag
  belongs_to :functional_test

  validates_uniqueness_of :tag_id, scope: :functional_test_id
end