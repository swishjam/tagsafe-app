import { Controller } from 'stimulus'

export default class extends Controller {
  hide() {
    this.element.classList.remove('show');
  }

  _onFormSubmit() {
    this.hide();
  }
}