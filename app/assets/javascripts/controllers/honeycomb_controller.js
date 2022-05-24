import { Controller } from 'stimulus'

export default class extends Controller {
  static values = { 
    tagUid: String,
    tagName: String,
    hasAudit: Boolean,
    rowNum: Number
  }
  isDisplayingTooltip = false

  connect() {
    this._initializeTooltip();
    this._listenForDismissal();
  }

  get honeycombDetailsForm() {
    return this.element.querySelector('[data-honeycomb-target="honeycombDetailsForm"]');
  }

  get tooltipHtml() {
    if(this.hasAuditValue) {
      return `
        <span id='honeycomb-tooltip-${this.tagUidValue}-dismiss' class='close-btn tagsafe-circular-btn tiny'><i class='fa fa-times'></i></span>
        <turbo-frame id='tag_${this.tagUidValue}_honeycomb_details' class='honeycomb-details-tooltip-content container-fluid p-3'>
          <h3 class='title'>${this.tagNameValue}</h3>
          <span class='spinner-border tagsafe-spinner small'></span>
        </turbo-frame>
      `;
    } else {
      return `
        <span id='honeycomb-tooltip-${this.tagUidValue}-dismiss' class='close-btn tagsafe-circular-btn tiny'><i class='fa fa-times'></i></span>
        <div class='honeycomb-details-tooltip-content container-fluid p-3'>
          <h6 class='title mb-3'>${this.tagNameValue} has no audits performed.</h6>
        </div>
      `;
    }
  }

  toggleTooltip() {
    if(this.isDisplayingTooltip) {
      this.hideTooltip();
    } else {
      this.tooltip.show();
      this._fetchAndDisplayHoneycombDetails();
      this.isDisplayingTooltip = true;
      this.element.classList.add('tooltip-displayed');
    }
  }

  hideTooltip() {
    this.tooltip.hide();
    this.isDisplayingTooltip = false;
    this.element.classList.remove('tooltip-displayed');
  }

  disconnect() {
    this.tooltip.dispose();
  }

  _fetchAndDisplayHoneycombDetails = () => {
    if(!this.hasAuditValue) return;
    this.honeycombDetailsForm.dispatchEvent(new CustomEvent('submit', { bubbles: true }));
  }

  _initializeTooltip = () => {
    this.tooltip = new bootstrap.Tooltip(this.element, { 
      title: this.tooltipHtml,
      html: true,
      trigger: 'manual',
      customClass: 'honeycomb-details-tooltip',
      placement: this.rowNumValue === 1 ? 'bottom' : 'auto',
      fallbackPlacements: ['bottom', 'top'],
      sanitize: false,
      offset: [0, 35]
    });
  }

  _listenForDismissal = () => {
    document.addEventListener('click', e => {
      if(e.target.id === `honeycomb-tooltip-${this.tagUidValue}-dismiss` || e.target.parentElement.id === `honeycomb-tooltip-${this.tagUidValue}-dismiss`) {
        this.hideTooltip();
      }
    })
  }
}