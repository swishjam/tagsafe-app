import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [];
  static values = {
    tagName: String,
    tagsafeScore: Number,
    previousTagsafeScore: Number
  }

  connect() {
    this._initTooltip();
  }

  _initTooltip = () => {
    this.tooltip = new bootstrap.Tooltip(this.element, { 
      title: `
        <h3 class="title mb-0">${this.tagsafeScoreValue < 80 ? '🚨' : ''} ${this.tagNameValue}</h3>
        <h5 class="title mt-3 mb-0">Tagsafe Score:</h5>
        <div class="progress-ring-container text-center mt-3 mb-0">
          <div class="progress-ring ${this.tagsafeScoreValue > 90 ? 'good' : this.tagsafeScoreValue > 80 ? 'warn' : 'danger'}">
            <svg>
              <circle class='inner-circle' cx="70" cy="70" r="70"></circle>
              <circle class='circle-outline animate' cx="70" cy="70" r="70" style='stroke-dashoffset: ${440 - (440*this.tagsafeScoreValue) / 100}'></circle>
            </svg>
            <div class="score default-cursor w-fit m-auto">
              <h2 class='position-relative'>${this.tagsafeScoreValue}</h2>
              <span data-controller='tooltip' data-bs-toggle="tooltip" data-placement="top" title="The previous audit had a Tagsafe Score of ${this.previousTagsafeScoreValue}.">
                <span><i class="fas ${this.previousTagsafeScoreValue > this.tagsafeScoreValue ? 'fa-long-arrow-alt-down' : 'fa-long-arrow-alt-up'}"></i> ${Math.abs(this.previousTagsafeScoreValue - this.tagsafeScoreValue).toFixed(2)}</span>
              </span>
            </div>
          </div>
        </div>
      `,
      template: `
        <div class="tooltip d-none d-lg-inline" role="tooltip">
          <div class="tooltip-inner"></div>
          <div class="tooltip-arrow"></div>
        </div>
      `,
      html: true,
      // trigger: 'manual',
      customClass: 'honeycomb-details-tooltip',
      sanitize: false,
      // offset: [0, 35]
    });
  }
}