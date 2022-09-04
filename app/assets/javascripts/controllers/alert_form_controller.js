import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['tagSwitch'];

  toggleAllTags() {
    this.tagSwitchTargets.forEach(el => {
      const isChecked = el.getAttribute('checked') === 'true';
      if(isChecked) {
        el.removeAttribute('checked');
        el.removeAttribute('disabled');
      } else {
        el.setAttribute('checked', 'true');
        el.setAttribute('disabled', 'true');
      }
    });
  }
}