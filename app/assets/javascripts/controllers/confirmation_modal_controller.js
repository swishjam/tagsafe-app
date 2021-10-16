import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['title', 'confirmationText', 'confirmationFormContainer'];

  connect() {
    this.element['confirmationModalController'] = this;
  }

  show() {
    this.element.classList.add('show');
  }

  hide() {
    this.element.classList.remove('show');
  }

  setConfirmationTitle(text) {
    this.titleTarget.innerText = text;
  }

  setConfirmationText(text) {
    this.confirmationTextTarget.innerText = text;
  }

  setForm(form) {
    this.form = form;
    this.confirmationFormContainerTarget.appendChild(form);
    this.form.addEventListener('submit', () => { this._onFormSubmit() });
  }

  _onFormSubmit() {
    this.hide();
  }
}