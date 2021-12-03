import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [];

  connect() {
    this.element.addEventListener("submit", event => {
      // if (event.detail.success) {
        this.element.classList.add('loading')
      // }
    })
  }
}