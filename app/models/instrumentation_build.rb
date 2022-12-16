class InstrumentationBuild < ApplicationRecord
  uid_prefix 'build'
  belongs_to :container
end