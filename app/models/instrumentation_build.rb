class InstrumentationBuild < ApplicationRecord
  include Streamable
  uid_prefix 'build'
  belongs_to :domain

  after_create :broadcast_new_build_notification

  private

  def broadcast_new_build_notification
    stream_notification_to_all_domain_users(
      domain: self.domain, 
      partial: 'instrumentation_builds/new_build_notification', 
      partial_locals: { instrumentation_build: self }, 
      timestamp: self.created_at.formatted_short
    )
  end
end