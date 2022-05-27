import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['browser', 'firstNotification', 'secondNotification', 'honeycombTooltip', 'gitDiffs'];
  thresholds = {
    firstNotification: 0.25,
    secondNotification: 0.50,
    gitDiffs: 0.80,
    honeycombTooltip: 0.85
  }

  connect() {
    this._setupScrollListeners();
  }

  _setupScrollListeners() {
    const options = { threshold: Object.values(this.thresholds) }
    this.observer = new IntersectionObserver(entries => this._onBrowserScrollIntoView(entries), options);
    this.observer.observe(this.browserTarget);
  }

  _onBrowserScrollIntoView = entries => {
    entries.forEach(entry => {
      if(entry.intersectionRatio >= this.thresholds.firstNotification) {
        this.firstNotificationTarget.classList.remove('hidden');
        setTimeout(() => this.firstNotificationTarget.classList.add('slide-in'), 250);
      }
      if(entry.intersectionRatio >= this.thresholds.secondNotification) {
        this.secondNotificationTarget.classList.remove('hidden');
        setTimeout(() => this.secondNotificationTarget.classList.add('slide-in'), 250);
      }
      if(entry.intersectionRatio >= this.thresholds.gitDiffs) {
        this.gitDiffsTarget.classList.remove('collapsed');
      }
      if(entry.intersectionRatio >= this.thresholds.honeycombTooltip) {
        // this._displayHoneycombTooltip();
        this.observer.disconnect();
      }
    })
  }

  _displayHoneycombTooltip = () => {
    const tooltip = new bootstrap.Tooltip(this.honeycombTooltipTarget, { 
      title: `
        <h3 class="title mb-0">🚨 Google Analytics 🚨</h3>
        <h5 class="title mt-1">Tagsafe Score:</h5>
        <div class="progress-ring-container text-center mt-3 mb-0">
          <div class="progress-ring danger">
            <svg preserveAspectRatio="xMinYMin meet">
              <circle class='inner-circle' cx="70" cy="70" r="70"></circle>
              <circle class='circle-outline animate' cx="70" cy="70" r="70" style='stroke-dashoffset: 189.9' data-parallax-dashboard-target='tagsafeScoreRing'></circle>
            </svg>
            <div class="score default-cursor w-fit m-auto">
              <h2 class='position-relative'>56.84</h2>
              <span data-controller='tooltip' data-bs-toggle="tooltip" data-placement="top" title="The previous audit had a Tagsafe Score of 87.23.">
                <span><i class="fas fa-long-arrow-alt-down"></i> 30.39</span>
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
      trigger: 'manual',
      customClass: 'honeycomb-details-tooltip',
      placement: 'bottom',
      sanitize: false,
      offset: [0, 35]
    });
    tooltip.show();
  }
}