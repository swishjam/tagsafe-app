import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['alertTypeDropdown', 'auditExceededThresholdFields'];

  connect() {
    this.currentlyDisplayedDynamicFormFields;
    this.alertTypeDropdownTarget.addEventListener('change', () => this._updateForm());
  }

  _updateForm = () => {
    if(this.currentlyDisplayedDynamicFormFields) this.currentlyDisplayedDynamicFormFields.classList.add('hidden')
    
    const selectedOption = this.alertTypeDropdownTarget.selectedOptions[0];
    if(selectedOption.disabled) return;
    this.currentlyDisplayedDynamicFormFields = {
      "AuditExceededThresholdAlertConfiguration": this.auditExceededThresholdFieldsTarget
    }[selectedOption.value];
    if(this.currentlyDisplayedDynamicFormFields) this.currentlyDisplayedDynamicFormFields.classList.remove('hidden')
  }
}