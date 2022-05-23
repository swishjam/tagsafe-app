class FunctionalTestToRun < ApplicationRecord
  self.table_name = :functional_tests_to_run

  belongs_to :tag
  belongs_to :functional_test

  validates_uniqueness_of :tag_id, scope: :functional_test_id, message: Proc.new{ |test_to_run| "#{test_to_run.tag.try_friendly_name} already has Functional Test #{functinoal_test.title} enabled." }
end