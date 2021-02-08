module Schedule
  class CleanOutOfRetentionDataJob
    def perform
      # One day export to CSVs?
      ScriptCheck.older_than(30.days.ago).destroy_all
    end
  end
end