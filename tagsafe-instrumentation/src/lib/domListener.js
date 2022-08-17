export default class DOMListener {
  constructor(element) {
    this.element = element;
    this.element.addEventListener('load', e => this._onLoad(e) );
    this.element.addEventListener('error', e => this._onError(e) );
  }

  _onLoad(e) {
    console.log(`${this.element} loaded!`);
    console.log(e);
  }

  _onError(e) {
    console.log(`${this.element} errored!`);
    console.log(e);
  }
}