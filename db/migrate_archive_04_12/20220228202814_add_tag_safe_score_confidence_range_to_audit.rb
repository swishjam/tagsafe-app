class AddTagSafeScoreConfidenceRangeToAudit < ActiveRecord::Migration[6.1]
  def up
    add_column :audits, :tagsafe_score_confidence_range, :float
  end
end
