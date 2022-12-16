class JsFileSizeAuditComponent < AuditComponent
  # -1 point for every 10,000 bytes (or 10kb)
  DEFAULT_BYTE_SIZE_MULTIPLIER = 0.0001

  def perform_audit!
    bytes = audit.tag_version.bytes
    score = bytes * DEFAULT_BYTE_SIZE_MULTIPLIER > 100 ? 0 : 100 - (bytes * DEFAULT_BYTE_SIZE_MULTIPLIER)
    completed!(score: score, raw_results: { bytes: bytes })
  end
end