import { Controller } from 'stimulus'

export default class extends Controller {
  initialize() {
    this.isSticky = false;
    this._addNavClassesIfNecessary(true);
    window.addEventListener('scroll', this._addNavClassesIfNecessary)
  }

  _addNavClassesIfNecessary = (ignoreStickyFlag = false) => {
    if(window.scrollY > 100 && (ignoreStickyFlag || !this.isSticky)) {
      this.element.classList.remove('transparent');
      this.element.classList.add('sticky-top', 'solid-white');
      this.isSticky = true;
    } else if(window.scrollY <= 100 && (ignoreStickyFlag || this.isSticky)) {
      this.element.classList.remove('sticky-top', 'solid-white');
      this.element.classList.add('transparent');
      this.isSticky = false;
    }
  }
}