import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['expandable', 'expandBtn', 'collapseBtn'];
  
  expand() {
    this.expandableTarget.classList.add('expanded');
    this.expandBtnTarget.classList.add('hidden');
    this.collapseBtnTarget.classList.remove('hidden');
  }

  collapse() {
    this.expandableTarget.classList.remove('expanded');
    this.expandBtnTarget.classList.remove('hidden');
    this.collapseBtnTarget.classList.add('hidden');
  }
}