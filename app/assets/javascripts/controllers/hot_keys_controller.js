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
    console.log(`Hotkey initiated!! ${this.action}`);
    const method = {
      modal: this._showModalAndFetchModelContent
    }[this.action];
    method();
  }

  _showModalAndFetchModelContent = () => {
    document.querySelector('#server-loadable-modal-container').classList.add('show');
    document.body.classList.add('locked');
    this.formActionTarget.dispatchEvent(new CustomEvent('submit', { bubbles: true }));
    // Turbo.visit(this.element.getAttribute('data-endpoint'));
  }

  _keydownListener = () => {
    window.addEventListener('keydown', e => {
      if(e.keyCode === 91) {
        this.commandIsKeyedDown = true;
      } else if(this.commandIsKeyedDown && e.keyCode === this.keyCode){
        e.preventDefault();
        this._triggerHotKeyAction();
      }
    })
  }

  _keyupListener = () => {
    window.addEventListener('keyup', e => {
      if(e.keyCode === 91) {
        this.commandIsKeyedDown = false;
      }
    })
  }
}