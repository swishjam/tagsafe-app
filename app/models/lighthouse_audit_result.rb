# class LighthouseAuditResult < ApplicationRecord
#   include Rails.application.routes.url_helpers
  
#   has_many :lighthouse_audit_result_metrics, dependent: :destroy
#   belongs_to :lighthouse_audit
#   # belongs_to :lighthouse_audit_type

#   has_one_attached :report_html

#   scope :by_audit_type, -> (audit_type) { where(lighthouse_audit_type: audit_type) }
#   scope :primary_audits, -> { joins(:lighthouse_audit).where(lighthouse_audits: { primary: true })}

#   after_destroy :purge_report_html

#   def formatted_performance_score
#     (performance_score*100).round(2)
#   end

#   # assume this should only be used for delta and averages, so we can grab the first audit type
#   # percent change = (original value - new value)/original value
#   def performance_score_percent_change
#     return 0.0 unless lighthouse_audit.previous_succesful_lighthouse_audit.present?
#     prev_score = lighthouse_audit.previous_succesful_lighthouse_audit.lighthouse_audit_results.by_audit_type(lighthouse_audit_type).first.formatted_performance_score
#     (((prev_score - formatted_performance_score)/prev_score)*100).round(2)
#   end

#   def report_file_url(only_path = true)
#     # figure out how to define host! we have env['host], does that work?
#     rails_blob_path(report_html.attachment, only_path: only_path)
#   end

#   def purge_report_html
#     report_html.purge
#   end
# end
