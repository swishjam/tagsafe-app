import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['leftHandNav', 'showBtn', 'hideBtn'];
  
  hide() {
    document.querySelector('#content').classList.add('collapsed-navigation');
    this.leftHandNavTarget.classList.add('collapsed');
    this.hideBtnTarget.classList.add('hidden');
    setTimeout(() => this.showBtnTarget.classList.remove('hidden'), 500);
  }

  show() {
    document.querySelector('#content').classList.remove('collapsed-navigation');
    this.leftHandNavTarget.classList.remove('collapsed');
    this.showBtnTarget.classList.add('hidden');
    setTimeout(() => this.hideBtnTarget.classList.remove('hidden'), 500);
  }

  leftHandNavClick() {
    // if(!this.leftHandNavTarget.classList.contains('collapsed-navigation')) {
    //   this.show();
    // }
  }
}