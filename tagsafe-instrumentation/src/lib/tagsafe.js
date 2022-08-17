import TagConfig from './tagConfig';
import TagInjector from './tagInjector';

export default class Tagsafe {
  static init({ 
    tagsToInjectImmediately,
    tagsToInjectOnLoad,
  }) {
    if(this._initialized) throw new Error(`Tagsafe already initialized.`);
    this._initialized = true;
    const tagConfigsToInjectImmediately = tagsToInjectImmediately.map(tagConfigHash => new TagConfig(tagConfigHash));
    const tagConfigsToInjectOnLoad = tagsToInjectOnLoad.map(tagConfigHash => new TagConfig(tagConfigHash));
    console.log(tagConfigsToInjectImmediately);
    console.log(tagConfigsToInjectOnLoad);
    const tagInjector = new TagInjector({ tagConfigsToInjectImmediately, tagConfigsToInjectOnLoad });
    tagInjector.injectTagsIntoDOM();
  }
}