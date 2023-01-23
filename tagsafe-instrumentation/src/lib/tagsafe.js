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

    const disableScriptInterception = Math.random() > settings.reRouteEligibleTagsSampleRate;
    const scriptInterceptor = new ScriptInterceptor({ 
      tagInterceptionRules, 
      dataReporter, 
      firstPartyDomains: settings.firstPartyDomains,
      disableScriptInterception,
      debugMode: settings.debugMode
    })
    scriptInterceptor.interceptInjectedScriptTags();

    const scriptInjector = new ScriptInjector({
      immediateScripts: tagConfigurations.immediate,
      onLoadScripts: tagConfigurations.onLoad,
      tagInterceptionRules,
      disableScriptInterception,
      debugMode: settings.debugMode
    })
    scriptInjector.beginInjecting();
    
    const thirdPartyTagIdentifier = new ThirdPartyTagIdentifier({
      dataReporter, 
      debugMode: settings.debugMode,
      firstPartyDomains: settings.firstPartyDomains
    })

    scriptInjector.afterAllTagsAdded(async () => {
      dataReporter.recordNumTagsafeInjectedTags(scriptInjector.numTagsInjected());
      dataReporter.recordNumTagsafeHostedTags(scriptInterceptor.numTagsHostedByTagsafe());
      dataReporter.recordNumTagsWithTagsafeOverriddenLoadStrategies(scriptInterceptor.numTagsWithTagsafeOverriddenLoadStrategies());
      dataReporter.recordNumTagsNotHostedByTagsafe(await thirdPartyTagIdentifier.numTagsNotHostedByTagsafe());
    })

    if(settings.debugMode) {
      console.log('%c[Tagsafe Log] TagsafeJS initialized', 'background-color: purple; color: white; padding: 5px;');
      console.log('%c[Tagsafe Log] Tag configurations:', 'background-color: purple; color: white; padding: 5px;');
      console.log(tagConfigurations);
      console.log('%c[Tagsafe Log] Tag intercept rules:', 'background-color: purple; color: white; padding: 5px;');
      console.log(tagInterceptionRules);
      console.log(`%c[Tagsafe Log] First party domain(s): ${settings.firstPartyDomains.join(', ')}`, 'background-color: purple; color: white; padding: 5px;');
      console.log(`%c[Tagsafe Log] Reporting sample rate: ${settings.reportingSampleRate * 100}%`, 'background-color: purple; color: white; padding: 5px;')
    }
  }
}