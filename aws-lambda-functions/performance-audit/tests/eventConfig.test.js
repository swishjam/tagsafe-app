const { config } = require('aws-sdk');
const EventConfig = require('../src/eventConfig'),
        mockEvent = require('./mockEvent');

// firstPartyRequestUrl: this._requiredEventConfig('first_party_request_url'),
// includePageLoadResources: this._booleanEventOptionsConfigFor('include_page_load_resources', false),
// includePageTracing: this._booleanEventOptionsConfigFor('include_page_tracing', false),
// inlineInjectedScriptTags: this._booleanEventOptionsConfigFor('inline_injected_script_tags', false),
// navigationTimeoutMs: this._eventOptionsConfigFor('puppeteer_page_timeout_ms', parseInt(process.env.PUPPETEER_PAGE_NAVIGATION_TIMEOUT_MS || 30_000)),
// navigationWaitUntil: this._eventOptionsConfigFor('puppeteer_page_wait_until', process.env.PUPPETEER_PAGE_NAVIGATION_WAIT_UNTIL || ['networkidle2', 'domcontentloaded']),
// overrideInitialHTMLRequestWithManipulatedPage: this._booleanEventOptionsConfigFor('override_initial_html_request_with_manipulated_page', false),
// pageUrlToPerformAuditOn: this._requiredEventConfig('page_url_to_perform_audit_on'),
// returnCachedResponsesImmediately: this._booleanEventOptionsConfigFor('return_cached_responses_immediately', process.env.RETURN_CACHED_RESPONSES_IMMEDIATELY === 'true'),
// scrollPage: this._booleanEventOptionsConfigFor('scroll_page', true),
// stripAllCSS: this._booleanEventOptionsConfigFor('strip_all_css', false),
// stripAllImages: this._booleanEventOptionsConfigFor('strip_all_images', process.env.STRIP_ALL_IMAGES || true),
// stripAllJS: false,
// thirdPartyTagUrlsAndRulesToInject: this._eventConfigFor('third_party_tag_urls_and_rules_to_inject'),
// thirdPartyTagUrlPatternsToAllow: this._eventConfigFor('third_party_tag_url_patterns_to_allow', []).concat(this._eventConfigFor('third_party_tag_urls_and_rules_to_inject').map(urlAndRule => urlAndRule.url)),
// thirdPartyTagUrlPatternsToNeverAllow: this._eventConfigFor('third_party_tag_url_patterns_to_never_allow', []),
// throwErrorIfDOMCompleteIsZero: this._booleanEventOptionsConfigFor('throw_error_if_dom_complete_is_zero', process.env.THROW_ERROR_IF_DOM_COMPLETE_IS_ZERO || true),
// userAgent: this._eventOptionsConfigFor('user_agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36')

const availableConfigs = [
  {
    configKey: 'allow_all_third_party_tags',
    returnedKey: 'allowAllThirdPartyTags',
    isBoolean: true,
    defaultValue: false
  }, 
  {
    configKey: 'cached_responses_s3_key',
    returnedKey: 'cachedResponsesS3Key',
    providedValue: 'some-s3-key', 
    expectedResult: 'some-s3-key',
    defaultValue: undefined
  }, 
  {
    configKey: 'enable_screen_recording',
    returnedKey: 'enableScreenRecording',
    isInOptionsHash: true,
    isBoolean: true,
    defaultValue: process.env.ENABLE_SCREEN_RECORDING === 'true'
  },
  // {
  //   configKey: 'first_party_request_url',
  //   returnedKey: 'firstPartyRequestUrl',
  //   providedValue: 'www.tagsafe.io',
  //   expectedResult: 'www.tagsafe.io',
  //   isRequiredConfig: true
  // }
];

const runTestForConfig = config => {
  if(config.isBoolean) {
    [
      { providedValue: true, expectedResult: true }, 
      { providedValue: false, expectedResult: false }, 
      { providedValue: 'true', expectedResult: true }, 
      { providedValue: 'false', expectedResult: false }
    ].forEach(testToRun => {
      runEventConfigTest({
        configKey: config.configKey,
        returnedKey: config.returnedKey,
        providedValue: testToRun.providedValue,
        expectedResult: testToRun.expectedResult,
        options: { providedKeyIsInOptionsHash: config.isInOptionsHash }
      })
    })
  } else {
    runEventConfigTest(config);
  }
  if(config.isRequiredConfig) {
    expect()
  } else {
    runEventConfigTest({
      configKey: config.configKey,
      returnedKey: config.returnedKey,
      providedValue: null,
      expectedResult: config.defaultValue,
      options: { providedKeyIsInOptionsHash: config.isInOptionsHash }
    })
  }
}

const runEventConfigTest = ({ configKey, returnedKey, providedValue, expectedResult, isRequiredConfig = false, options = {} }) => {
  test(`Sets ${returnedKey} EventConfig to '${expectedResult}' when '${providedValue}' (${typeof providedValue}) is provided`, () => {
    if(options['providedKeyIsInOptionsHash']) {
      if(providedValue === null) {
        delete mockEvent['options'][configKey];
      } else {
        mockEvent['options'][configKey] = providedValue;
      }
    } else {
      if(providedValue === null) {
        delete mockEvent[configKey];
      } else {
        mockEvent[configKey] = providedValue;
      }
    }
    const fullConfigFunc = new EventConfig(mockEvent).constructPerformanceAuditConfig;
    if(isRequiredConfig) {
      expect(fullConfigFunc).toThrow(`${configKey} is a required event option but is undefined.`)
    } else {
      expect(fullConfigFunc()[returnedKey]).toEqual(expectedResult);
    }
  });
}

availableConfigs.forEach(runTestForConfig);
