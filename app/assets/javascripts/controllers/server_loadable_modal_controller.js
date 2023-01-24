import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['loadingIndicator', 'dynamicContent', 'title', 'subTitle'];

  connect() {
    this._listenForEscape();
  }

  hide() {
    document.body.classList.remove('locked');
    this.element.classList.add('hidden');
    this._clearModalContent();
  }

  close() { this.hide() }

  _listenForEscape() {
    window.addEventListener('keydown', e => {
      if(e.keyCode === 27) this.hide();
    })
  }

  _onFormSubmit() {
    this.hide();
  }

  _clearModalContent() {
    this.loadingIndicatorTarget.classList.remove('hidden');
    this.dynamicContentTarget.remove();
    this.titleTarget.remove();
    if(this.subTitleTarget) this.subTitleTarget.remove();
  }
}