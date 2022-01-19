import { Controller } from 'stimulus'

export default class extends Controller {
  initialize() {
    this.element.addEventListener('click', e => {
      e.preventDefault();
      const idToScrollTo = e.srcElement.getAttribute('data-anchor');
      // const offset = e.srcElement.getAttribute('data-offset') || 0;
      const el = document.getElementById(idToScrollTo);
      // const scrollPos = el.offset().top - offset;
      el.scrollIntoView({ behavior: 'smooth' });

      // $("html, body").animate({ scrollTop: scrollPos });
    })
  }
}