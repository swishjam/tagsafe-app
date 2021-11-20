import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['leftHandNav', 'showBtn', 'hideBtn'];
  
  hide() {
    document.querySelector('#content').classList.add('full-width');
    this.leftHandNavTarget.classList.add('collapsed');
    this.showBtnTarget.classList.remove('hidden');
    this.hideBtnTarget.classList.add('hidden');
  }

  show() {
    document.querySelector('#content').classList.remove('full-width');
    this.leftHandNavTarget.classList.remove('collapsed');
    this.showBtnTarget.classList.add('hidden');
    this.hideBtnTarget.classList.remove('hidden');
  }

  leftHandNavClick() {
    // if(!this.leftHandNavTarget.classList.contains('full-width')) {
    //   this.show();
    // }
  }
}