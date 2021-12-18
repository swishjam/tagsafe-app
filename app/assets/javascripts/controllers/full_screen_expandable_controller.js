import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['expandable', 'expandBtn', 'collapseBtn'];
  
  expand() {
    this.expandableTarget.classList.add('expanded');
    try {
      this.expandBtnTarget.classList.add('hidden');
      this.collapseBtnTarget.classList.remove('hidden');
    } catch(e) { console.warn(e) }
  }

  collapse() {
    this.expandableTarget.classList.remove('expanded');
    try {
      this.expandBtnTarget.classList.remove('hidden');
      this.collapseBtnTarget.classList.add('hidden');
    } catch(e) { console.warn(e) }
  }

  toggle() {
    if(this.expandableTarget.classList.contains('expanded')) {
      this.collapse();
    } else {
      this.expand();
    }
  }
}