import { Controller } from 'stimulus'

export default class extends Controller {
  initialize() {
    const scrollOffset = parseInt(this.element.getAttribute('data-scroll-offset') || 0);
    const idToScrollTo = this.element.getAttribute('data-anchor');
    const el = document.getElementById(idToScrollTo);
    if(el) {
      const yCoordsToScrollTo = el.offsetTop - scrollOffset;
      this.element.addEventListener('click', e => {
        e.preventDefault();
        window.scrollTo({
          top: yCoordsToScrollTo,
          behavior: 'smooth'
        })
      })
    }
  }
}