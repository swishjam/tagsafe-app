export default class TagConfig {
  constructor(tagConfigurationHash) {
    this.tagConfigurationHash = tagConfigurationHash;
  }

  _ = () => this._optionalAttr('_');
  uid = () => this._requiredAttr('uid');
  el = () => this._requiredAttr('el');
  loadRule = () => this._requiredAttr('loadRule');
  script = () => this._requiredAttr('script');
  directTagUrl = () => this._requiredAttr('directTagUrl');
  tagsafeHostedTagUrl = () => this.tagConfigurationHash['tagsafeHostedTagUrl'] || this.directTagUrl();
  injectLocation = () => this._requiredAttr('injectLocation');
  sha256 = () => this._requiredAttr('sha256');

  toJson = () => {
    return {
      uid: this.uid(),
      el: this.el(),
      loadRule: this.loadRule(),
      directTagUrl: this.directTagUrl(),
      tagsafeHostedTagUrl: this.tagsafeHostedTagUrl(),
      injectLocation: this.injectLocation(),
      sha256: this.sha256(),
      script: this.script()
    }
  }

  _optionalAttr(attribute) {
    const attr = this.tagConfigurationHash[attribute];
    return attr === '' ? null : attr;    
  }

  _requiredAttr(attribute) {
    const attr = this.tagConfigurationHash[attribute];
    if(typeof attr === 'undefined') throw new Error(`TagConfig is missing required attribute: ${attribute}`);
    return attr === '' ? null : attr;
  }
}