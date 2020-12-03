class ScriptCheck < ApplicationRecord
  belongs_to :script
  belongs_to :script_check_region, optional: true

  scope :successful, -> { where(response_code: 200) }
  scope :failed, -> { where.not(response_code: 200) }

  def self.log!(response_code:, response_time:, script:, region: nil)
    create!(
      response_code: response_code, 
      script: script, 
      response_time_ms: response_time,
      script_check_region: region
    )
  end
end