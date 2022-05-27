import { Controller } from 'stimulus'

export default class extends Controller {
  showDescription(e) {
    const selector = e.target.getAttribute('data-description-target');
    const existingDescription = this.element.querySelector('.feature-description:not(.hidden)');
    if(existingDescription) existingDescription.classList.add('hidden');
    this.element.querySelector(selector).classList.remove('hidden');
  }
}