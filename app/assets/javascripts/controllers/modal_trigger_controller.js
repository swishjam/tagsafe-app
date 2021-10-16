import { Controller } from 'stimulus'

export default class extends Controller {
  connect() {
    this.element.addEventListener('click', () => this.showModal() )
  }

  showModal() {
    document.querySelector('#server-loadable-modal-container').classList.add('show');
  }
}