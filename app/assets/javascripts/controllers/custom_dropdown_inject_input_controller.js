import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['injectedInputContainer'];
  static values = {
    injectedInputName: String
  };

  injectAsInput = e => {
    const dropdownItemSelected = e.srcElement;
    const inputContainer = document.createElement('div');
    inputContainer.className = 'injected-input-container tagsafe-pill grey m-1';
    inputContainer.innerText = dropdownItemSelected.getAttribute('data-input-text');

    const input = document.createElement('input');
    input.setAttribute('name', this.injectedInputNameValue);
    input.setAttribute('value', dropdownItemSelected.getAttribute('data-input-value'));
    input.setAttribute('type', 'hidden');
    input.className = 'injected-input';

    const closeBtn = document.createElement('div');
    closeBtn.className = 'close-btn tagsafe-circular-btn tiny p-1';
    const closeIcon = document.createElement('i');
    closeIcon.className = 'fa fa-times';
    closeBtn.appendChild(closeIcon);
    closeBtn.addEventListener('click', () => {
      inputContainer.remove();
      dropdownItemSelected.classList.remove('hidden');
    })

    inputContainer.appendChild(input);
    inputContainer.appendChild(closeBtn);
    this.injectedInputContainerTarget.appendChild(inputContainer);

    dropdownItemSelected.classList.add('hidden');
  }
}