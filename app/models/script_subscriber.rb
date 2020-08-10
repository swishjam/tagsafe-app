class ScriptSubscriber < ApplicationRecord
  belongs_to :organization
  belongs_to :monitored_script
end