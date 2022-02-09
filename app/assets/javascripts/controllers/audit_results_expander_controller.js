import { Controller } from "stimulus"

export default class AuditResultsExpanderController extends Controller {
  static targets = ['expandBtn', 'collapseBtn', 'metricsContainer'];

  expandMetrics() {
    this.collapseBtnTarget.classList.remove('hidden');
    this.expandBtnTarget.classList.add('hidden');
    this.metricsContainerTarget.classList.remove('minimized');
  }

  collapseMetrics() {
    this.expandBtnTarget.classList.remove('hidden');
    this.collapseBtnTarget.classList.add('hidden');
    this.metricsContainerTarget.classList.add('minimized');
  }
}