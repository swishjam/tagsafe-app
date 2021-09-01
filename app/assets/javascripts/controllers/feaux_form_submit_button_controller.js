import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('click', () => this._submitForm() )
  }

  _submitForm() {
    this.element.closest('form').dispatchEvent(new CustomEvent('submit', { bubbles: true }));
  }
}
