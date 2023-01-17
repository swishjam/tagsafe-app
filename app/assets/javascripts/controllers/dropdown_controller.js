import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    this.menu = this.element.children[1]
  }

  toggle() {
    let menu = this.menu
    if(this.menu.classList.contains('hidden')) {
      // Show
      this.menu.classList.remove('hidden')
      setTimeout(function () {
        menu.classList.replace('opacity-0', 'opacity-100')
      }, 50);
    } else {
      // Hide
      this.menu.classList.replace('opacity-100', 'opacity-0')
      setTimeout(function () {
        menu.classList.add('hidden')
      }, 200);
    }
  }
}
