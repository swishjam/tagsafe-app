import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [];
  bottomMostDisplayedLineEl = null;
  topMostDisplayedLineEl = null;
  additionsCount = 0;
  deletionsCount = 0;
  diffType = this.element.getAttribute('data-diff-type');
  
  connect() {
    this.element['diffController'] = this;
    this._handleDiffs();
    this._showChangeMetrics();
  }

  showLinesAbove() {
    let currentEl = this.topMostDisplayedLineEl;
    for(var i = 0; i < 10; i++) {
      if(this._tryShowLine(currentEl.previousElementSibling)) {
        currentEl = currentEl.previousElementSibling;
        this.topMostDisplayedLineEl = currentEl;
      } else {
        break;
      }
    }
  }

  showLinesBelow() {
    let currentEl = this.bottomMostDisplayedLineEl;
    for(var i = 0; i < 10; i++) {
      if(this._tryShowLine(currentEl.nextElementSibling)) {
        currentEl = currentEl.nextElementSibling;
        this.bottomMostDisplayedLineEl = currentEl;
      } else {
        break;
      }
    }
  }

  _showChangeMetrics() {
    if(this.diffType == 'unified') {
      document.querySelector('#additions-count').innerText = this.additionsCount;
      document.querySelector('#deletions-count').innerText = this.deletionsCount;
    } else if(this.diffType === 'additions') {
      document.querySelector('#additions-count').innerText = this.additionsCount;
    } else if(this.diffType === 'deletions') {
      document.querySelector('#deletions-count').innerText = this.deletionsCount;
    }
  }

  _handleDiffs() {
    this.element.querySelectorAll('li.ins, li.del').forEach(el => {
      this._handleDiff(el);
    })
  }

  _handleDiff(el) {
    this._unHideSurroundingLines(el);
    this._countChange(el);
  }

  _unHideSurroundingLines(el) {
    let lineAbove = el.previousElementSibling;
    if(this._tryShowLine(lineAbove)) {
      this.topMostDisplayedLineEl = lineAbove;
    }
    if(this._tryShowLine(lineAbove.previousElementSibling)) {
      this.topMostDisplayedLineEl = lineAbove.previousElementSibling;
    }

    let lineBelow = el.nextElementSibling;
    if(this._tryShowLine(lineBelow)) {
      this.bottomMostDisplayedLineEl = lineBelow;
    }
    if(this._tryShowLine(lineBelow.nextElementSibling)) {
      this.bottomMostDisplayedLineEl = lineBelow.nextElementSibling;
    }
  }

  _countChange(el) {
    if(el.classList.contains('ins')) {
      this.additionsCount += 1;
    } else if(el.classList.contains('del')) {
      this.deletionsCount += 1;
    }
  }

  _tryShowLine(lineEl) {
    if(lineEl.nodeName === 'LI' && lineEl.classList.contains('unchanged')) {
      lineEl.classList.add('display');
      return true;
    }
  }
}