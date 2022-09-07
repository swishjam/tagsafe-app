import Tagsafe from './lib/tagsafe';
import configuration from '../data/config'

window.Tagsafe = Tagsafe;

const searchParams = new URLSearchParams(window.location.search);
const useDirectTagUrlsOnly = searchParams.get('tagsafe-direct_url_only') === 'true';

const config = {
  disabledTags: [],
  enabledTags: [],
  useDirectTagUrlsOnly: useDirectTagUrlsOnly,
  ...configuration
};

window.Tagsafe.init(config);