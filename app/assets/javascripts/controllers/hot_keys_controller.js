import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['formAction'];

  action = this.element.getAttribute('data-action');
  keyCode = parseInt(this.element.getAttribute('data-key-code'));

  connect = () => {
    this._setKeydownListener();
  }

  disconnect = () => {
    window.removeEventListener('keydown', this._onKeyDown);
  }

  _triggerHotKeyAction = () => {
    const method = {
      modal: this._showModalAndFetchModelContent,
      form: this._submitFormActionTarget
    }[this.action];
    method();
  }

  _submitFormActionTarget = () => {
    this.formActionTarget.dispatchEvent(new CustomEvent('submit', { bubbles: true }));
  }

  _showModalAndFetchModelContent = () => {
    document.querySelector('#server-loadable-modal-container').classList.add('show');
    document.body.classList.add('locked');
    this._submitFormActionTarget();
  }

  _setKeydownListener = () => {
    window.addEventListener('keydown', this._onKeyDown = e => {
      const commandKeyIsPressed = e.metaKey;
      if(commandKeyIsPressed && e.keyCode === this.keyCode){
        e.preventDefault();
        this._triggerHotKeyAction();
      }
    })
  }
}