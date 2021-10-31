import { Controller } from "stimulus"

export default class AuditResultsExpanderController extends Controller {
  static targets = ['expandBtn', 'collapseBtn', 'metricsContainer'];

  expandMetrics() {
    this.collapseBtnTarget.classList.remove('active');
    this.expandBtnTarget.classList.add('active');
    this.metricsContainerTarget.classList.remove('minimized');
  }

  collapseMetrics() {
    this.collapseBtnTarget.classList.add('active');
    this.expandBtnTarget.classList.remove('active');
    this.metricsContainerTarget.classList.add('minimized');
  }
}