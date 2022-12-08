import MetricsHandler from './metricsHandler';
import DataReporter from "./dataReporter";
import ScriptInterceptor from './scriptInterceptor';

export default class Tagsafe {
  static init({ domainUid, tagConfigurations, settings }) {
    if(this._initialized) throw new Error(`Tagsafe already initialized.`);
    this._initialized = true;
    
    window.Tagsafe.metricsHandler = new MetricsHandler;
    
    const dataReporter = new DataReporter({ 
      reportingURL: settings.reportingURL,
      domainUid,
      sampleRate: settings.sampleRate,
      debugMode: settings.debugMode
    });

    const scriptInterceptor = new ScriptInterceptor({ 
      tagConfigurations, 
      dataReporter, 
      firstPartyDomains: settings.firstPartyDomains,
      debugMode: settings.debugMode
    });

    scriptInterceptor.interceptInjectedScriptTags();

    if(settings.debugMode) {
      console.log('TagsafeJS initialized with');
      console.log(tagConfigurations);
      console.log(`First party domain(s): ${settings.firstPartyDomains.join(', ')}`);
      console.log(`Reporting sample rate: ${settings.sampleRate * 100}%`)
    }
  }
}