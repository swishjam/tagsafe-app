class TestRunWithoutTag < TestRun
  uid_prefix 'trwot'
  
  belongs_to :audit
end