import { Controller } from 'stimulus'

export default class extends Controller {
  changeActionDictionary = {
    'select': 'change',
    'checkbox': 'change',
    'radio': 'change',
    'number': 'blur',
    'text': 'blur',
    'file': 'change'
  };

  connect() {
    this._setInputListeners();
  }

  _submitForm() {
    this.element.dispatchEvent(new CustomEvent('submit', { bubbles: true }))
  }

  _setInputListeners() {
    this.element.querySelectorAll('input:not([data-ignore-changes]), select:not([data-ignore-changes])').forEach((e) => { this._listenToInput(e) });
  }

  _listenToInput(el) {
    let changeAction = this.changeActionDictionary[el.type];
    if(changeAction) {
      el.addEventListener(changeAction, () => { 
        this._submitForm();
      });
    }
  }
}