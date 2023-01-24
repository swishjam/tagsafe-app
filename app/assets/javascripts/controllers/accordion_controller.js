import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['openStateChevron', 'closedText', 'openedText', 'accordionDiv'];

  toggleAccordion() {
    const isOpening = this.accordionDivTarget.classList.contains('hidden');
    if(isOpening) {
      this.accordionDivTarget.classList.remove('hidden');
      this.openedTextTarget.classList.remove('hidden');
      this.closedTextTarget.classList.add('hidden');
      this.openStateChevronTarget.classList.add('rotate-90');
      window.dispatchEvent(new Event('resize'));
    } else {
      this.accordionDivTarget.classList.add('hidden');
      this.openedTextTarget.classList.add('hidden');
      this.closedTextTarget.classList.remove('hidden');
      this.openStateChevronTarget.classList.remove('rotate-90');
    }
  }
}