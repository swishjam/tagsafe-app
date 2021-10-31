import { Controller } from 'stimulus'

export default class ConfirmableFormChangesController extends Controller {
  get confirmationModalController() {
    return document.querySelector('#confirmation-modal-container').confirmationModalController;
  }

  get urlToConfirm() {
    return this.element.getAttribute('action');
  }

  get confirmationRequestMethod() {
    return this.element.getAttribute('method') || 'POST';
  }

  get confirmationText() {
    return this.element.getAttribute('data-confirmation-text');
  }

  get submitButtonText() {
    return this.element.getAttribute('data-confirmation-button-text') || 'Submit';
  }

  confirmChange(e) {
    debugger;
    this.confirmationModalController.setFormUrl(this._urlForChangedInput(e.target));
    this.confirmationModalController.setFormMethod(this.confirmationRequestMethod);
    this.confirmationModalController.setConfirmationText(this.confirmationText);
    this.confirmationModalController.setSubmitButtonText(this.submitButtonText);
    this.confirmationModalController.show();
  }

  _urlForChangedInput(input) {
    return this.urlToConfirm+'?'+e.target.name+'='+e.target.value;
  }
}