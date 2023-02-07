import Tagsafe from './lib/tagsafe';
import configuration from '../data/config'
import { urlToDomain } from './lib/utils';
import { ErrorReporter } from './lib/errorReporter';

const params = new URLSearchParams(window.location.search);

if(params.has('tagsafe-disabled') || params.has('disable-tagsafe')) {
  console.warn('Tagsafe is disabled.');
} else {
  window.Tagsafe = Tagsafe;
  window.Tagsafe.config = configuration;
  const { uid, tagInterceptionRules, settings } = configuration;
  const errorReporter = new ErrorReporter({ reportingURL: settings.reportingURL, containerUid: uid });
  try {
    const reRouteEligibleTagsSampleRateConfig = params.has('tagsafe-disable-tag-re-route') ? 0 : settings.reRouteEligibleTagsSampleRate;
    const reportingSampleRateConfig = params.has('tagsafe-force-reporting') ? 1.0 : settings.reportingSampleRate;

    const mergedSettings = {
      reportingURL: 'https://tagsafe-api.tagsafe.workers.dev', // gets overridden if provided in Instrumentation settings
      firstPartyDomains: [urlToDomain(window.location.href)], // gets overridden if provided in Instrumentation settings
      debugMode: params.has('tagsafe-debugger'),
      ...settings,
      reRouteEligibleTagsSampleRate: typeof reRouteEligibleTagsSampleRateConfig === 'undefined' ? 1.0 : reRouteEligibleTagsSampleRateConfig, // overrides whatever was set in Instrumentation settings
      reportingSampleRate: typeof reportingSampleRateConfig === 'undefined' ? 0.05 : reportingSampleRateConfig, // overrides whatever was set in Instrumentation settings
    }

    window.Tagsafe.init({
      containerUid: uid,
      settings: mergedSettings,
      errorReporter,
      tagInterceptionRules,
      tagConfigurations
    });
  } catch(err) {
    errorReporter.reportError(err.message);
  }
}