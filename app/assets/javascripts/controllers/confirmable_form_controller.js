import { Controller } from 'stimulus'

export default class ConfirmableFormController extends Controller {
  get confirmationModalController() {
    return document.querySelector('#confirmation-modal-container').confirmationModalController;
  }

  get confirmationTitle() {
    return this.element.getAttribute('data-confirmation-title');
  }

  get confirmationText() {
    return this.element.getAttribute('data-confirmation-text');
  }

  connect() {
    this.element.addEventListener('submit', (e) => { this._onConfirmableFormSubmit(e)  })
  }

  _onConfirmableFormSubmit(e) {
    e.preventDefault();
    this._showConfirmation();
  }

  _showConfirmation() {
    if(this.confirmationModalController.form !== this._clonedForm()) {
      this.confirmationModalController.setForm(this._clonedForm());
      this.confirmationModalController.setConfirmationTitle(this.confirmationTitle);
      this.confirmationModalController.setConfirmationText(this.confirmationText);
    }
    this.confirmationModalController.show();
  }

  _clonedForm() {
    if(!this.clonedForm) {
      let clonedForm = this.element.cloneNode(true);
      clonedForm.removeAttribute('data-controller');
      clonedForm.removeAttribute('data-confirmation-title');
      clonedForm.removeAttribute('data-confirmation-text');
      clonedForm.classList.add('text-end');
      let visibleUserInputs = clonedForm.querySelectorAll('input:not([type="submit"], select');
      visibleUserInputs.forEach(el => el.type = 'hidden');
      
      let previousSubmitBtn = clonedForm.querySelector('[type="submit"]');
      if(previousSubmitBtn) {
        previousSubmitBtn.remove();
      }
      
      let newSubmitBtn = document.createElement('input');
      newSubmitBtn.type = 'submit';
      newSubmitBtn.classList.add('tagsafe-btn');
      newSubmitBtn.value = previousSubmitBtn ? previousSubmitBtn.value : 'Submit';
      clonedForm.appendChild(newSubmitBtn);

      this.clonedForm = clonedForm;
    }
    return this.clonedForm;
  }
}