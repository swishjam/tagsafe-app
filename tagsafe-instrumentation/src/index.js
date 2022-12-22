import Tagsafe from './lib/tagsafe';
import configuration from '../data/config'
import { urlToDomain } from './lib/utils';

const params = new URLSearchParams(window.location.search);

if(configuration.disabled || params.has('tagsafe-disabled') || params.has('disable-tagsafe')) {
  console.warn('Tagsafe is disabled.');
} else {
  window.Tagsafe = Tagsafe;
  window.Tagsafe.config = configuration;
  const { uid, tagConfigurations, urlPatternsToNotCapture, settings } = configuration;
  
  const mergedSettings = {
    reportingURL: 'https://tagsafe-api.tagsafe.workers.dev',
    firstPartyDomains: [urlToDomain(window.location.href)],
    debugMode: params.has('tagsafe-debugger'),
    ...settings
  }

  window.Tagsafe.init({ 
    containerUid: uid, 
    settings: mergedSettings,
    tagConfigurations,
    urlPatternsToNotCapture
  });
}