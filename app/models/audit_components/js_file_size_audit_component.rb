class JsFileSizeAuditComponent < AuditComponent
  include ActionView::Helpers::NumberHelper
  # -1 point for every 10,000 bytes (or 10kb)
  DEFAULT_BYTE_SIZE_MULTIPLIER = 0.0001

  self.friendly_name = 'File Size'

  def perform_audit!
    bytes = audit.tag_version.bytes
    score = bytes * DEFAULT_BYTE_SIZE_MULTIPLIER > 100 ? 0 : 100 - (bytes * DEFAULT_BYTE_SIZE_MULTIPLIER)
    completed!(score: score, raw_results: { bytes: bytes })
  end

  def explanation
    "#{audit.tag.try_friendly_name} file size measured #{number_to_human_size(raw_results['bytes'])}."
  end

  def audit_breakdown_description
    "#{audit.tag.try_friendly_name} file size is #{number_to_human_size(raw_results['bytes'])}, which is larger than recommended."
  end
end