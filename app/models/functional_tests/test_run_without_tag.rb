class TestRunWithoutTag < TestRun
  uid_prefix 'trwot'
  belongs_to :audit

  def self.friendly_class_name
    'Test Run Without Tag'
  end
end