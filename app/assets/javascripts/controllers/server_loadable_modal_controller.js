import { Controller } from 'stimulus'

export default class extends Controller {
  // static targets = ['contentTurboFrame'];

  hide() {
    this.element.classList.remove('show');
    this._clearModalContent();
  }

  _onFormSubmit() {
    this.hide();
  }

  _clearModalContent() {
    this.element.querySelector('turbo-frame#server_loadable_modal_content').innerHTML = "<div class='text-center'><span class='spinner-border tagsafe-spinner medium'></span></div>";
  }
}