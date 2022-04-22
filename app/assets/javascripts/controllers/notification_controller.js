import { Controller } from "stimulus"

export default class extends Controller {
  persistNotification = this.element.getAttribute('data-persist-notification') === 'true';

  connect() {
    setTimeout(() => { this.element.classList.add('animate') }, 100);
    if(!this.persistNotification) {
      let timeoutMs = parseInt(this.element.getAttribute('timeout') || '8000');
      setTimeout(() => { this.dismiss() }, timeoutMs);
    }
  }

  dismiss() {
    this.element.classList.remove('animate');
    setTimeout(() => { this.element.remove() }, 500); // wait for animation off screen to stop
  }
}
