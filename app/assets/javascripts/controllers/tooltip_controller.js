import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    this.tooltip = new bootstrap.Tooltip(this.element);
  }

  disconnect() {
    this.tooltip.dispose();
  }
}
