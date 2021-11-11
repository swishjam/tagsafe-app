import { Controller } from 'stimulus'

export default class extends Controller {
  onResourceMouseover(e) {
    let resourceEls = this.element.querySelectorAll(`[data-resource="${e.srcElement.getAttribute('data-resource')}"`);
    resourceEls.forEach(el => el.classList.add('highlight'));
  }

  onResourceMouseout() {
    let highlightedEls = document.querySelectorAll('.highlight[data-resource]');
    highlightedEls.forEach(el => el.classList.remove('highlight'));
  }
}