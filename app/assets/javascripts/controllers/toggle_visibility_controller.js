import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['toggler'];

  connect() {
    this._findTogglableEls();
    this.togglerTarget.addEventListener('change', () => this._toggleEl());
  }

  _toggleEl() {
    if(this.togglerTarget.checked) {
      this.elsToDisplayWhenToggledOn.forEach(el => el.classList.remove('hidden'));
      this.elsToDisplayWhenToggledOff.forEach(el => el.classList.add('hidden'));
    } else {
      this.elsToDisplayWhenToggledOn.forEach(el => el.classList.add('hidden'));
      this.elsToDisplayWhenToggledOff.forEach(el => el.classList.remove('hidden'));
    }
  }

  _findTogglableEls() {
    this.elsToDisplayWhenToggledOn = [];
    this.elsToDisplayWhenToggledOff = [];
    this.togglerTarget.getAttribute('data-display-toggled-on-selectors').split(',').forEach(selector => {
      this.elsToDisplayWhenToggledOn.push(...Array.from(this.element.querySelectorAll(selector)));
    });
    this.togglerTarget.getAttribute('data-display-toggled-off-selectors').split(',').forEach(selector => {
      this.elsToDisplayWhenToggledOff.push(...Array.from(this.element.querySelectorAll(selector)));
    });
  }
}