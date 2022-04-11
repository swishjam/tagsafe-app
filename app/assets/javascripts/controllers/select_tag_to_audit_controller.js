import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['submitForm', 'submitBtn', 'tagSelector'];

  connect() {
    this.tagSelectorTarget.addEventListener('change', e => {
      this.submitFormTarget.setAttribute('action', `/tags/${e.target.value}/audits/new`);
      this.submitBtnTarget.removeAttribute('disabled')
    })
  }
}