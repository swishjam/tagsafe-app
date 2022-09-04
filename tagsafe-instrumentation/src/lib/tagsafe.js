import TagInjector from './tagInjector';
import TagConfig from './tagConfig';
import ErrorHandler from './errorHandler';
import MetricsHandler from './metricsHandler';

export default class Tagsafe {
  static init(config = {
    tagsToInjectImmediately: [], 
    tagsToInjectOnLoad: [],
    useDirectTagUrl: false,
    tagsToDisable: []
  }) {
    if(this._initialized) throw new Error(`Tagsafe already initialized.`);
    this._initialized = true;
    
    window.Tagsafe.config = config;
    const errorHandler = new ErrorHandler;
    const metricsHandler = new MetricsHandler;
    window.Tagsafe.errorHandler = errorHandler;
    window.Tagsafe.metricsHandler = metricsHandler;
    
    const tagConfigsToInjectImmediately = config.tagsToInjectImmediately.map(tagConfigHash => new TagConfig(tagConfigHash));
    const tagConfigsToInjectOnLoad = config.tagsToInjectOnLoad.map(tagConfigHash => new TagConfig(tagConfigHash));
    const tagInjector = new TagInjector({ 
      tagConfigsToInjectImmediately, 
      tagConfigsToInjectOnLoad,
      errorHandler,
      metricsHandler
    });
    tagInjector.injectTagsIntoDOM();
  }
}