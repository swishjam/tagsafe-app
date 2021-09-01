import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['select']

  updateFormAction(e) {
    this.element.setAttribute('action', this.selectTarget.selectedOptions[0].value);
  }

  submitForm() {
    this.element.dispatchEvent(new CustomEvent('submit', { bubbles: true }))
  }
}