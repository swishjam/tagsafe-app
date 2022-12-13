module.exports = {
  "page_url_to_perform_audit_on":"https://www.tagsafe.io",
  "first_party_request_url":"https://www.tagsafe.io",
  "third_party_tag_urls_and_rules_to_inject":[],
  "third_party_tag_url_patterns_to_allow":[],
  "cached_responses_s3_key":null,
  "options": {
     "override_initial_html_request_with_manipulated_page":"true",
      "puppeteer_page_timeout_ms":0,
      "enable_screen_recording":"true",
      "throw_error_if_dom_complete_is_zero":"true",
      "include_page_load_resources":"false",
      "include_page_tracing":"false",
      "inline_injected_script_tags":"false",
      "scroll_page":"false",
      "strip_all_images":"true",
      "strip_all_css":"false"
    }
  }