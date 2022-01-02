import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['video'];
  callbacks = this.videoTarget.getAttribute('data-callbacks')

  connect() {
    // Called any time the controller is connected to the DOM
  }
}