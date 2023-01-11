import MetricsHandler from './metricsHandler';
import DataReporter from "./dataReporter";
import ScriptInterceptor from './scriptInterceptor';
import ThirdPartyTagIdentifier from './thirdPartyTagIdentifier';
import ScriptInjector from './scriptInjector';

export default class Tagsafe {
  static init({ containerUid, tagConfigurations, tagInterceptionRules, settings }) {
    if(this._initialized) throw new Error(`Tagsafe already initialized.`);
    this._initialized = true;

    const pageLoadId = `ts-${crypto.randomUUID()}`;
    const pageLoadTs = new Date();
    window.Tagsafe.pageLoadId = () => pageLoadId;
    window.Tagsafe.pageLoadTs = () => pageLoadTs;
        
    const dataReporter = new DataReporter({ 
      containerUid,
      reportingURL: settings.reportingURL,
      reportingSampleRate: settings.reportingSampleRate,
      debugMode: settings.debugMode
    });

    new MetricsHandler(dataReporter);

    new ScriptInterceptor({ 
      tagInterceptionRules, 
      dataReporter, 
      firstPartyDomains: settings.firstPartyDomains,
      disableScriptInterception: Math.random() > settings.reRouteEligibleTagsSampleRate,
      debugMode: settings.debugMode
    }).interceptInjectedScriptTags();

    new ScriptInjector({
      immediateScripts: tagConfigurations.immediate,
      onLoadScripts: tagConfigurations.onLoad,
      debugMode: settings.debugMode
    });
    
    new ThirdPartyTagIdentifier({
      dataReporter, 
      debugMode: settings.debugMode,
      firstPartyDomains: settings.firstPartyDomains
    }).reportAllThirdPartyTags();

    if(settings.debugMode) {
      console.log('TagsafeJS initialized with');
      console.log('Tag configurations:');
      console.log(tagConfigurations);
      console.log('Tag intercept rules:')
      console.log(tagInterceptionRules);
      console.log(`First party domain(s): ${settings.firstPartyDomains.join(', ')}`);
      console.log(`Reporting sample rate: ${settings.reportingSampleRate * 100}%`)
    }
  }
}