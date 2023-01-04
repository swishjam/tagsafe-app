import MetricsHandler from './metricsHandler';
import DataReporter from "./dataReporter";
import ScriptInterceptor from './scriptInterceptor';
import ThirdPartyTagIdentifier from './thirdPartyTagIdentifier';

export default class Tagsafe {
  static init({ containerUid, tagConfigurations, settings }) {
    if(this._initialized) throw new Error(`Tagsafe already initialized.`);
    this._initialized = true;

    const pageLoadId = `ts-${crypto.randomUUID()}`;
    const pageLoadTs = new Date();
    window.Tagsafe.pageLoadId = () => pageLoadId;
    window.Tagsafe.pageLoadTs = () => pageLoadTs;
        
    const dataReporter = new DataReporter({ 
      containerUid,
      reportingURL: settings.reportingURL,
      sampleRate: settings.sampleRate,
      debugMode: settings.debugMode
    });

    new MetricsHandler(dataReporter);

    new ScriptInterceptor({ 
      tagConfigurations, 
      dataReporter, 
      firstPartyDomains: settings.firstPartyDomains,
      debugMode: settings.debugMode
    }).interceptInjectedScriptTags();
    
    new ThirdPartyTagIdentifier({
      dataReporter, 
      debugMode: settings.debugMode,
      firstPartyDomains: settings.firstPartyDomains
    }).reportAllThirdPartyTags();

    if(settings.debugMode) {
      console.log('TagsafeJS initialized with');
      console.log('Tag intercept configurations:');
      console.log(tagConfigurations);
      console.log(`First party domain(s): ${settings.firstPartyDomains.join(', ')}`);
      console.log(`Reporting sample rate: ${settings.sampleRate * 100}%`)
    }
  }
}