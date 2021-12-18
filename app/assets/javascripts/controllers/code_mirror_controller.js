import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [];
  readOnly = this.element.getAttribute('data-readonly') === 'true' ? 'nocursor' : false;
  disableLineNumbers = this.element.getAttribute('data-disable-line-numbers') === 'true';

  connect() {
    CodeMirror.fromTextArea(this.element, { 
      lineNumbers: !this.disableLineNumbers,
      styleActiveLine: true,
      matchBrackets: true,
      readOnly: this.readOnly
    });
    this.element.classList.remove('hidden');
  }
}