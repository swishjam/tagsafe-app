import { Controller } from "stimulus"

export default class extends Controller {
  persistNotification = this.element.getAttribute('data-persist-notification') === 'true';
  autoDismissMs = parseInt(this.element.getAttribute('timeout') || '8000');

  connect() {
    this._animateIn();
    this._setAutoDismissTimer();
    this._hoverListener();
  }

  dismiss() {
    this.element.style['margin-right'] = '-100vw';
    setTimeout(() => { this.element.remove() }, 1_000); // wait for animation off screen to stop
  }

  _animateIn() {
    this.displayedAtTimestamp = Date.now();
    setTimeout(() => this.element.style['margin-right'] = '0', 100);
  }

  _setAutoDismissTimer(timeoutMs = this.autoDismissMs) {
    if(this.persistNotification) return;
    this.autoDismissTimeoutFunc = setTimeout(() => { this.dismiss() }, timeoutMs);
  }

  _hoverListener() {
    if(this.persistNotification) return;
    this.element.addEventListener('mouseover', () => {
      this.timeRemainingOnAutoDismissAtTimeOfHover = Date.now() - this.displayedAtTimestamp;
      clearTimeout(this.autoDismissTimeoutFunc);
    });
    this.element.addEventListener('mouseout', () => {
      this._setAutoDismissTimer(this.timeRemainingOnAutoDismissAtTimeOfHover || this.autoDismissMs);
    });
  }
}
