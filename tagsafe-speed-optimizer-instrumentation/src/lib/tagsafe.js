import MetricsHandler from './metricsHandler';
import DataReporter from "./dataReporter";
import { NodeInterceptor } from './nodeInterceptor';

export default class Tagsafe {
  static init({ containerUid, tagInterceptionRules, settings, errorReporter }) {
    if(this._initialized) throw new Error(`Tagsafe already initialized.`);
    this._initialized = true;

    const pageLoadId = `ts-${Date.now()}-${parseInt(Math.random() * 1_000_000_000_000)}`;
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

    const disableScriptInterception = Math.random() > settings.reRouteEligibleTagsSampleRate;
    const nodeInterceptor = new NodeInterceptor({ 
      tagInterceptionRules, 
      dataReporter, 
      firstPartyDomains: settings.firstPartyDomains,
      disableScriptInterception,
      errorReporter,
      debugMode: settings.debugMode
    })
    nodeInterceptor.interceptInjectedScriptTags();

    if(settings.debugMode) {
      console.log('%c[Tagsafe Log] TagsafeJS initialized', 'background-color: #7587f8; color: white; padding: 5px;');
      console.log('%c[Tagsafe Log] Tag intercept rules:', 'background-color: #7587f8; color: white; padding: 5px;');
      console.log(tagInterceptionRules);
      console.log(`%c[Tagsafe Log] First party domain(s): ${settings.firstPartyDomains.join(', ')}`, 'background-color: #7587f8; color: white; padding: 5px;');
      console.log(`%c[Tagsafe Log] Reporting sample rate: ${settings.reportingSampleRate * 100}%`, 'background-color: #7587f8; color: white; padding: 5px;')
    }
  }
}