import { Controller } from 'stimulus'

export default class extends Controller {
  get confirmationModalController() {
    return document.querySelector('#confirmation-modal-container').confirmationModalController;
  }

  get urlToConfirm() {
    return this.element.getAttribute('data-confirmation-url');
  }

  get confirmationRequestMethod() {
    return this.element.getAttribute('data-confirmation-method') || 'GET';
  }

  get confirmationText() {
    return this.element.getAttribute('data-confirmation-text');
  }

  get submitButtonText() {
    return this.element.getAttribute('data-confirmation-button-text') || 'Submit';
  }

  showConfirmation() {
    this.confirmationModalController.setFormUrl(this.urlToConfirm);
    this.confirmationModalController.setFormMethod(this.confirmationRequestMethod);
    this.confirmationModalController.setConfirmationText(this.confirmationText);
    this.confirmationModalController.setSubmitButtonText(this.submitButtonText);
    this.confirmationModalController.show();
  }
}