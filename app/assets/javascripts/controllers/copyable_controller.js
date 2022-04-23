import { Controller } from 'stimulus'

export default class extends Controller {
  connect() {
    this.textToCopy = this.element.innerText;
    this._insertCopyIcon();
  }

  _insertCopyIcon() {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    const path1 = document.createElementNS('http://www.w3.org/2000/svg','path');
    const path2 = document.createElementNS('http://www.w3.org/2000/svg','path');

    svg.setAttribute('height', '16');
    svg.setAttribute('width', '16');
    svg.setAttribute('viewBox', '0 0 16 16');
    svg.classList.add('copy-btn', 'ms-1');

    path1.setAttribute('d', "M0 6.75C0 5.784.784 5 1.75 5h1.5a.75.75 0 010 1.5h-1.5a.25.25 0 00-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 00.25-.25v-1.5a.75.75 0 011.5 0v1.5A1.75 1.75 0 019.25 16h-7.5A1.75 1.75 0 010 14.25v-7.5z");
    path1.setAttribute('fill-rule', 'evenodd');
    path2.setAttribute('d', 'M5 1.75C5 .784 5.784 0 6.75 0h7.5C15.216 0 16 .784 16 1.75v7.5A1.75 1.75 0 0114.25 11h-7.5A1.75 1.75 0 015 9.25v-7.5zm1.75-.25a.25.25 0 00-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 00.25-.25v-7.5a.25.25 0 00-.25-.25h-7.5z');
    path2.setAttribute('fill-rule', 'evenodd');
    svg.appendChild(path1);
    svg.appendChild(path2)
    
    svg.addEventListener('click', e => this._copy(e));
    this.element.append(svg);
  }

  _copy(_e) {
    navigator.clipboard.writeText(this.textToCopy);
    this._flashTooltip();
  }

  _flashTooltip() {
    this.element.setAttribute('data-bs-toggle', 'tooltip');
    this.element.setAttribute('title', 'Copied!');
    const tooltip = new bootstrap.Tooltip(this.element);
    tooltip.show();
    setTimeout(() => {
      tooltip.dispose();
      this.element.removeAttribute('data-bs-toggle');
      this.element.removeAttribute('data-bs-original-title');
      this.element.removeAttribute('title');
    }, 3_000);
  }
}