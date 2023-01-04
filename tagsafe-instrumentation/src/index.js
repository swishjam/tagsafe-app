import Tagsafe from './lib/tagsafe';
import configuration from '../data/config'
import { urlToDomain } from './lib/utils';

const params = new URLSearchParams(window.location.search);

if(params.has('tagsafe-disabled') || params.has('disable-tagsafe')) {
  console.warn('Tagsafe is disabled.');
} else {
  window.Tagsafe = Tagsafe;
  window.Tagsafe.config = configuration;
  const { uid, tagConfigurations, urlPatternsToNotCapture, settings } = configuration;
  
  const mergedSettings = {
    reportingURL: 'https://tagsafe-api.tagsafe.workers.dev', // gets overridden if provided in Instrumentation settings
    firstPartyDomains: [urlToDomain(window.location.href)], // gets overridden if provided in Instrumentation settings
    debugMode: params.has('tagsafe-debugger'),
    ...settings,
    sampleRate: params.has('tagsafe-force-reporting') ? 1.0 : settings.sampleRate, // overrides whatever was set in Instrumentation settings
  }

  window.Tagsafe.init({ 
    containerUid: uid, 
    settings: mergedSettings,
    tagConfigurations,
    urlPatternsToNotCapture
  });
}