import Tagsafe from './lib/tagsafe';
import config from '../data/config'

window.Tagsafe = Tagsafe;
window.Tagsafe.config = config;
window.Tagsafe.init({ 
  tagsToInjectImmediately: config.tagsToInjectImmediately, 
  tagsToInjectOnLoad: config.tagsToInjectOnLoad 
});