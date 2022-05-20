import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    this.tooltip = new bootstrap.Tooltip(this.element, { customClass: this.element.getAttribute('data-bs-custom-class') || '' });
  }

  disconnect() {
    this.tooltip.dispose();
  }
}
