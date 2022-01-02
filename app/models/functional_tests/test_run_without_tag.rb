class TestRunWithoutTag < TestRun
  uid_prefix 'trwot'
  belongs_to :audit
  belongs_to :original_test_run_with_tag, class_name: 'TestRunWithTag'

  def self.friendly_class_name
    'Test Run Without Tag'
  end
end