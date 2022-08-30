import Tagsafe from './lib/tagsafe';
import configuration from '../data/config'

window.Tagsafe = Tagsafe;
const config = {
  disabledTags: [],
  enabledTags: [],
  useDirectTagUrl: false,
  ...configuration
};

window.Tagsafe.init(config);