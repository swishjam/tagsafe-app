import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['toggler', 'elToToggle'];

  connect() {
    this.togglerTarget.addEventListener('change', () => this._toggleEl());
  }

  _toggleEl() {
    console.log('changing...')
    if(this.togglerTarget.checked) {
      this.elToToggleTarget.classList.remove('hidden');
    } else {
      this.elToToggleTarget.classList.add('hidden');
    }
  }
}