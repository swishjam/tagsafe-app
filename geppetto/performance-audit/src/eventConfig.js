class EventConfig {
  constructor(event) {
    this.event = event;
    this.event.options = this.event.options || {};
  }

  constructPerformanceAuditConfig = () => {
    this._performanceAuditConfig = {
      allowAllThirdPartyTags: this._booleanEventConfigFor('allow_all_third_party_tags', false),
      cachedResponsesS3Key: this._eventConfigFor('cached_responses_s3_key'),
      enableScreenRecording: this._booleanEventOptionsConfigFor('enable_screen_recording', process.env.ENABLE_SCREEN_RECORDING === 'true'),
      firstPartyRequestUrl: this._requiredEventConfig('first_party_request_url'),
      includePageLoadResources: this._booleanEventOptionsConfigFor('include_page_load_resources', false),
      includePageTracing: this._booleanEventOptionsConfigFor('include_page_tracing', false),
      inlineInjectedScriptTags: this._booleanEventOptionsConfigFor('inline_injected_script_tags', false),
      navigationTimeoutMs: this._eventOptionsConfigFor('puppeteer_page_timeout_ms', parseInt(process.env.PUPPETEER_PAGE_NAVIGATION_TIMEOUT_MS || 30_000)),
      navigationWaitUntil: this._eventOptionsConfigFor('puppeteer_page_wait_until', process.env.PUPPETEER_PAGE_NAVIGATION_WAIT_UNTIL || ['networkidle2', 'domcontentloaded']),
      overrideInitialHTMLRequestWithManipulatedPage: this._booleanEventOptionsConfigFor('override_initial_html_request_with_manipulated_page', false),
      pageUrlToPerformAuditOn: this._requiredEventConfig('page_url_to_perform_audit_on'),
      returnCachedResponsesImmediately: this._booleanEventOptionsConfigFor('return_cached_responses_immediately', process.env.RETURN_CACHED_RESPONSES_IMMEDIATELY === 'true'),
      scrollPage: this._booleanEventOptionsConfigFor('scroll_page', true),
      stripAllCSS: this._booleanEventOptionsConfigFor('strip_all_css', false),
      stripAllImages: this._booleanEventOptionsConfigFor('strip_all_images', process.env.STRIP_ALL_IMAGES || true),
      stripAllJS: false,
      thirdPartyTagUrlsAndRulesToInject: this._eventConfigFor('third_party_tag_urls_and_rules_to_inject'),
      thirdPartyTagUrlPatternsToAllow: this._eventConfigFor('third_party_tag_url_patterns_to_allow', []).concat(this._eventConfigFor('third_party_tag_urls_and_rules_to_inject').map(urlAndRule => urlAndRule.url)),
      thirdPartyTagUrlPatternsToNeverAllow: this._eventConfigFor('third_party_tag_url_patterns_to_never_allow', []),
      throwErrorIfDOMCompleteIsZero: this._booleanEventOptionsConfigFor('throw_error_if_dom_complete_is_zero', process.env.THROW_ERROR_IF_DOM_COMPLETE_IS_ZERO || true),
      uploadFilmstripFramesToS3: this._booleanEventOptionsConfigFor('upload_filmstrip_frames_to_s3', true),
      userAgent: this._eventOptionsConfigFor('user_agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36')
    }
    this._logPerformanceAuditConfig();
    return this._performanceAuditConfig;
  }

  constructCacheGeneratorConfig = () => {
    this._cacheGeneratorConfig = {
      allowAllThirdPartyTags: this._booleanEventConfigFor('allow_all_third_party_tags', false),
      firstPartyRequestUrl: this._requiredEventConfig('first_party_request_url'),
      pageUrlToGenerateCacheFrom: this._requiredEventConfig('page_url_to_perform_audit_on'),
      scrollPage: this._booleanEventOptionsConfigFor('scroll_page', true),
      stripAllImages: this._booleanEventOptionsConfigFor('strip_all_images', process.env.STRIP_ALL_IMAGES || true),
      thirdPartyTagUrlsAndRulesToInject: this._requiredEventConfig('third_party_tag_urls_and_rules_to_inject'),
      thirdPartyTagUrlPatternsToAllow: this._eventConfigFor('third_party_tag_url_patterns_to_allow', []).concat(this._eventConfigFor('third_party_tag_urls_and_rules_to_inject').map(urlAndRule => urlAndRule.url)),
    }
    this._logCacheGeneratorConfig();
    return this._cacheGeneratorConfig;
  }

  _requiredEventConfig = eventKey => {
    return this._eventConfigFor(eventKey) || new Error(`${eventKey} is a required event option but is undefined.`);
  }

  _eventConfigFor = (eventKey, fallbackValue) => {
    const eventVal = this.event[eventKey]
    return typeof eventVal === 'undefined' ? fallbackValue : eventVal;
  }

  _booleanEventConfigFor = (eventKey, fallbackValue) => {
    return this._eventConfigFor(eventKey, (fallbackValue || false)).toString() === 'true';
  }

  _eventOptionsConfigFor = (optionKey, fallbackValue) => {
    const eventOptionVal = this.event.options[optionKey];
    return typeof eventOptionVal === 'undefined' ? fallbackValue : eventOptionVal;
  }

  _booleanEventOptionsConfigFor = (eventKey, fallbackValue) => {
    return this._eventOptionsConfigFor(eventKey, (fallbackValue || false).toString()).toString() === 'true';
  }

  _logPerformanceAuditConfig = () => {
    console.log(`
      Performance Audit Config:

      allowAllThirdPartyTags: ${this._performanceAuditConfig['allowAllThirdPartyTags']}
      cachedResponsesS3Key: ${this._performanceAuditConfig['cachedResponsesS3Key']}
      enableScreenRecording: ${this._performanceAuditConfig['enableScreenRecording']}
      firstPartyRequestUrl: ${this._performanceAuditConfig['firstPartyRequestUrl']}
      includePageLoadResources: ${this._performanceAuditConfig['includePageLoadResources']}
      inlineInjectedScriptTags: ${this._performanceAuditConfig['inlineInjectedScriptTags']}
      navigationTimeoutMs: ${this._performanceAuditConfig['navigationTimeoutMs']}
      navigationWaitUntil: ${this._performanceAuditConfig['navigationWaitUntil']}
      overrideInitialHTMLRequestWithManipulatedPage: ${this._performanceAuditConfig['overrideInitialHTMLRequestWithManipulatedPage']}
      pageUrlToPerformAuditOn: ${this._performanceAuditConfig['pageUrlToPerformAuditOn']}
      returnCachedResponsesImmediately: ${this._performanceAuditConfig['returnCachedResponsesImmediately']}
      scrollPage: ${this._performanceAuditConfig['scrollPage']}
      stripAllImages: ${this._performanceAuditConfig['stripAllImages']}
      stripAllCSS: ${this._performanceAuditConfig['stripAllCSS']}
      stripAllJS: ${this._performanceAuditConfig['stripAllJS']}
      thirdPartyTagUrlsAndRulesToInject: ${JSON.stringify(this._performanceAuditConfig['thirdPartyTagUrlsAndRulesToInject'])}
      thirdPartyTagUrlPatternsToAllow: ${this._performanceAuditConfig['thirdPartyTagUrlPatternsToAllow']}
      thirdPartyTagUrlPatternsToNeverAllow: ${this._performanceAuditConfig['thirdPartyTagUrlPatternsToNeverAllow']}
      throwErrorIfDOMCompleteIsZero: ${this._performanceAuditConfig['throwErrorIfDOMCompleteIsZero']}
      userAgent: ${this._performanceAuditConfig['userAgent']}
    `)
  }
  _logCacheGeneratorConfig = () => {
    console.log(`
      Cache Generator Config:

      allowAllThirdPartyTags ${this._cacheGeneratorConfig['allowAllThirdPartyTags']}
      firstPartyRequestUrl ${this._cacheGeneratorConfig['firstPartyRequestUrl']}
      pageUrlToGenerateCacheFrom ${this._cacheGeneratorConfig['pageUrlToGenerateCacheFrom']}
      scrollPage ${this._cacheGeneratorConfig['scrollPage']}
      stripAllImages ${this._cacheGeneratorConfig['stripAllImages']}
      thirdPartyTagUrlsAndRulesToInject ${JSON.stringify(this._cacheGeneratorConfig['thirdPartyTagUrlsAndRulesToInject'])}
      thirdPartyTagUrlPatternsToAllow ${this._cacheGeneratorConfig['thirdPartyTagUrlPatternsToAllow']}
    `)
  }
}

module.exports = EventConfig;