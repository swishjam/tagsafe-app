import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['browser', 'firstNotification', 'secondNotification', 'tagsafeScoreRing', 'gitDiffs'];
  thresholds = {
    firstNotification: 0.25,
    secondNotification: 0.50,
    gitDiffs: 0.80,
    tagsafeScore: 0.85
  }

  connect() {
    this._setupScrollListeners();
  }

  _setupScrollListeners() {
    const options = { threshold: Object.values(this.thresholds) }
    const observer = new IntersectionObserver(this._onBrowserScrollIntoView, options);
    observer.observe(this.browserTarget);
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
      if(entry.intersectionRatio >= this.thresholds.tagsafeScore) {
        this.tagsafeScoreRingTarget.classList.remove('hidden');
        this.tagsafeScoreRingTarget.classList.add('animate');
      }
    })
  }
}