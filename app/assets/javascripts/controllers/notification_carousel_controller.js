import { Controller } from 'stimulus'

export default class extends Controller {
  initialize() {
    const totalItems = parseInt(this.element.getAttribute('data-num-items'));
    let currentNumItem = 1;
    setInterval(() => {
      currentNumItem === totalItems ? currentNumItem = 1 : currentNumItem += 1;
      this._animateItemIn(currentNumItem);
    }, 7500);
  }

  _animateItemIn = itemNum => {
    this.element.style = `margin-left: -${(itemNum*100) - 100}%`;
  }
}