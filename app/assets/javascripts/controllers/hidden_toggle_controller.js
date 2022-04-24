import { Controller } from 'stimulus'

export default class extends Controller {
  unHideSelectors = this.element.getAttribute('data-unhide-targets') || '';
  hideSelectors = this.element.getAttribute('data-hide-targets') || '';

  connect() {
    this.element.addEventListener('click', () => {
      this.hideTargets();
      this.unHideTargets();
    })
  }

  hideTargets() {
    const selectors = this.hideSelectors.split(',');
    if(selectors === ['']) return;
    selectors.forEach(selector => {
      const el = selector.trim() === 'self' ? this.element : document.querySelector(selector.trim());
      el.classList.add('hidden');
    })
  }

  unHideTargets() {
    const selectors = this.unHideSelectors.split(',');
    if(selectors === ['']) return;
    selectors.forEach(selector => {
      const el = document.querySelector(selector.trim());
      el.classList.remove('hidden');
    })
  }
}