import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['formAction'];

  action = this.element.getAttribute('data-action');
  keyCode = parseInt(this.element.getAttribute('data-key-code'));

  connect() {
    this._keydownListener();
    this._keyupListener();
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

  _keydownListener = () => {
    window.addEventListener('keydown', e => {
      if(e.keyCode === 18) {
        this.commandIsKeyedDown = true;
      } else if(this.commandIsKeyedDown && e.keyCode === this.keyCode){
        e.preventDefault();
        this._triggerHotKeyAction();
      }
    })
  }

  _keyupListener = () => {
    window.addEventListener('keyup', e => {
      if(e.keyCode === 18) {
        this.commandIsKeyedDown = false;
      }
    })
  }
}