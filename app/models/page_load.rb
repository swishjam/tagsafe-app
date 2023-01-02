class PageLoad < ApplicationRecord
  belongs_to :container
  belongs_to :page_url
  has_many :tags, foreign_key: :page_load_found_on_id
  
  has_many :page_load_performance_metrics, dependent: :destroy
  has_one :dom_complete_performance_metric
  has_one :dom_interactive_performance_metric
  has_one :time_to_first_byte_performance_metric
  has_one :total_blocking_time_performance_metric
  has_one :first_contentful_paint_performance_metric

  validates :page_load_identifier, presence: true, uniqueness: true

  before_create { self.tagsafe_consumer_received_at = Time.current }

  def processing_completed!
    raise "Cannot mark PageLoad processing complete, `page_load_ts` is nil." if page_load_ts.nil?
    raise "Cannot mark PageLoad processing complete, `enqueued_at` is nil." if enqueued_at.nil?
    raise "Cannot mark PageLoad processing complete, `tagsafe_consumer_received_at` is nil." if tagsafe_consumer_received_at.nil?
    update!(tagsafe_consumer_processed_at: Time.current, seconds_to_complete: Time.current - page_load_ts)
  end
end