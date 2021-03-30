module DataRetention
  class Base
    def purge!
      start_time = Time.now
      Rails.logger.info @purge_log_message || "Purging #{records_to_purge.count} #{records_to_purge.class.to_s.gsub('::ActiveRecord_Relation', '')}s"
      records_to_purge.destroy_all
      Rails.logger.info @purge_log_message || "#{records_to_purge.class.to_s.gsub('::ActiveRecord_Relation', '')} purge completed in #{Time.now - start_time} seconds."
    end
  end
end