class TestRunWithTag < TestRun
  belongs_to :audit
  belongs_to :test_run_without_tag

  def self.friendly_class_name
    'Test Run With Tag'
  end
end