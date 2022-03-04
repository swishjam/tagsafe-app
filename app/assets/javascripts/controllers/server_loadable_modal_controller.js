import { Controller } from 'stimulus'

export default class extends Controller {
  hide() {
    document.body.classList.remove('locked');
    this.element.classList.remove('show');
    this._clearModalContent();
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