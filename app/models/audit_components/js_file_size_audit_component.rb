class JsFileSizeAuditComponent < AuditComponent
  include ActionView::Helpers::NumberHelper
  # -1 point for every 10,000 bytes (or 10kb)
  DEFAULT_BYTE_SIZE_MULTIPLIER = 0.0001
  LOAD_TYPE_MULTIPLIER = {
    'defer' => 0.0,
    'async' => 5.0,
    'synchronous' => 15.0,
  }

  self.friendly_name = 'File Size'

  def perform_audit!
    bytes = get_tag_version_or_live_version_bytesize
    return if failed?
    score = generate_score(bytes)
    completed!(score: score, raw_results: { bytes: bytes, load_type: audit.tag.load_type })
  end

  def explanation
    "#{audit.tag.tag_snippet.name.capitalize} file size measured #{number_to_human_size(raw_results['bytes'])} in size."
  end
  alias raw_results_explanation explanation

  private

  def generate_score(bytes)
    detraction = bytes * DEFAULT_BYTE_SIZE_MULTIPLIER * (1.0 + LOAD_TYPE_MULTIPLIER[audit.tag.load_type]/100.0)
    detraction > 100 ? 0 : 100 - detraction
  end

  def get_tag_version_or_live_version_bytesize
    return audit.tag_version.bytes if audit.tag_version
    
    resp = HTTParty.get(audit.tag.full_url)
    return resp.to_s.bytesize unless resp.code > 299

    failed!("Unable to reach #{audit.tag.full_url}, endpoint returned a #{response.code} response.")
    false
  end
end