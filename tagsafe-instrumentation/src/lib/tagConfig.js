export default class TagConfig {
  constructor(tagConfigurationHash, options = { useDirectTagUrlsOnly: false }) {
    this.tagConfigurationHash = tagConfigurationHash;
    this.useDirectTagUrlsOnly = options.useDirectTagUrlsOnly;
    console.log(`Should TagConfig \`useDirectTagUrlsOnly\`? ${this.useDirectTagUrlsOnly}`);
  }

  _ = () => this._optionalAttr('_');
  uid = () => this._requiredAttr('uid');
  el = () => this._requiredAttr('el');
  loadRule = () => this._requiredAttr('loadRule');
  script = () => this._providedOrGeneratedScript();
  directTagUrl = () => this._requiredAttr('directTagUrl');
  tagsafeHostedTagUrl = () => this._tagsafeHostedUrlBasedOnOptions();
  injectLocation = () => this._requiredAttr('injectLocation');
  sha256 = () => this._sha256BasedOnOptions();

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

  _tagsafeHostedUrlBasedOnOptions = () => {
    return this.useDirectTagUrlsOnly ? null : this._optionalAttr('tagsafeHostedTagUrl');
  }

  _sha256BasedOnOptions = () => {
    return this.useDirectTagUrlsOnly ? null : this._optionalAttr('sha256');
  }

  _providedOrGeneratedScript = () => {
    // if only a script URL is provided without a JS script, mimic a script that 
    // will get intercepted and appropriate rules will be set
    return this._optionalAttr('script') || `(function(scriptUrl, injectLocation) {var s = document.createElement("script");s.setAttribute("src", scriptUrl);s.setAttribute("data-tagsafe-injected", "true");var domLocation={head: document.head,body: document.body}[injectLocation];domLocation.appendChild(s);})("${this.directTagUrl()}", "${this.injectLocation()}")`
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