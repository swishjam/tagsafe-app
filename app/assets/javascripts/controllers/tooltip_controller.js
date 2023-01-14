import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    // this.tooltip = new bootstrap.Tooltip(this.element, { customClass: this.element.getAttribute('data-bs-custom-class') || '' });
    // this.tooltip = new bootstrap.Tooltip(this.element, { 
    //   trigger: this.element.getAttribute('data-tooltip-trigger') || 'hover',
    //   customClass: 'tagsafe-tooltip',
    //   template: `
    //     <div class="tooltip" role="tooltip">
    //       <div class="tooltip-inner"></div>
    //       <div class="tooltip-arrow"></div>
    //     </div>
    //   `
    // });
  }

  disconnect() {
    // this.tooltip.dispose();
  }
}
