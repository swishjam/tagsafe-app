export default class TagConfig {
  constructor(tagConfigurationHash) {
    this.tagConfigurationHash = tagConfigurationHash;
  }

  el = () => this._requiredAttr('el');
  loadRule = () => this._requiredAttr('loadRule');
  tagsafeHostedTagUrl = () => this._requiredAttr('tagsafeHostedTagUrl');
  directTagUrl = () => this._requiredAttr('directTagUrl');
  injectLocation = () => this._requiredAttr('injectLocation');
  sriValue = () => this._requiredAttr('sriValue');

  _requiredAttr(attribute) {
    return this.tagConfigurationHash[attribute] || new Error(`TagConfig is missing required attribute: ${attribute}`);
  }
}