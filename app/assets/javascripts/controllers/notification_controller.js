import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    setTimeout(() => { this.element.classList.add('animate') }, 100);
    let timeoutMs = parseInt(this.element.getAttribute('timeout') || '8000');
    setTimeout(() => { this.dismiss() }, timeoutMs);
  }

  dismiss() {
    this.element.classList.remove('animate');
    setTimeout(() => { this.element.remove() }, 1000); // wait for animation off screen to stop
  }
}
