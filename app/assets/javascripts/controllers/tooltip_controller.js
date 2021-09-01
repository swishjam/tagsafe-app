import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    new bootstrap.Tooltip(this.element)
  }
}
