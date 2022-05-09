import { Controller } from 'stimulus'

export default class extends Controller {
  connect() {
    this._listenForEscape();
    this._listenToDismissOnTurboRenders();
  }

  hide() {
    document.body.classList.remove('locked');
    this.element.classList.remove('show');
    this._clearModalContent();
  }

  close() { this.hide() }

  _listenForEscape() {
    window.addEventListener('keydown', e => {
      if(e.keyCode === 27) this.hide();
    })
  }

  _listenToDismissOnTurboRenders() {
    document.documentElement.addEventListener('turbo:frame-render', (event) => {
      debugger;
    })
    document.documentElement.addEventListener('turbo:render', (event) => {
      debugger;
    })
    document.documentElement.addEventListener('turbo:frame-load', (event) => {
      debugger;
    })
  }

  _onFormSubmit() {
    this.hide();
  }

  _clearModalContent() {
    this.element.querySelector('.tagsafe-modal-title').innerText = null;
    this.element.querySelector('.tagsafe-modal-dynamic-content').innerHTML = null;
    this.element.querySelector('.tagsafe-modal-loading-container').classList.remove('hidden');
  }
}