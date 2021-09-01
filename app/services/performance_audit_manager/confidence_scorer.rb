module PerformanceAuditManager
  class ConfidenceScorer
    attr_accessor :with_tag_std_dev, :without_tag_std_dev

    def initialize(audt:, with_tag_results:, without_tag_results:)
      @audit = audit
      @with_tag_results = with_tag_results
      @without_tag_results = without_tag_results
    end

    def record_score!
      raise AlreadyScorerError, 'Cannot update confidence scores, audit has already been scored' unless @audit.with_tag_std_dev.nil?
      @audit.update!(
        
      )
      with_tag_std_dev = Statistics.std_dev(@with_tag_results)
      without_tag_std_dev = Statistics.std_dev(@without_tag_results)
    end
  end
end