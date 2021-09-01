import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [];

  connect() {
    this._setHoverListeners();
  }

  _setHoverListeners() {
    this.element.querySelectorAll('[data-highlight-key]').forEach(el => {
      this._setListener(el);
    })
  }

  _setListener(el) {
    el.addEventListener('mouseover', () => {
      this._highlightLogLines(el.getAttribute('data-highlight-key'));
    })
    el.addEventListener('mouseout', () => {
      this._unhighlightLogLines(el.getAttribute('data-highlight-key'));
    })
  }

  _highlightLogLines(highlightKey) {
    this.element.querySelectorAll(`[data-highlight-key="${highlightKey}"]`).forEach((el) => {
      el.classList.add('highlight');
    })
  }

  _unhighlightLogLines(highlightKey) {
    this.element.querySelectorAll(`[data-highlight-key="${highlightKey}"]`).forEach((el) => {
      el.classList.remove('highlight');
    })
  }
}