import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [];

  connect() {
    CodeMirror.fromTextArea(this.element, { 
      lineNumbers: true,
      styleActiveLine: true,
      matchBrackets: true,
      readOnly: this.element.getAttribute('data-readonly') === 'true' ? 'nocursor' : false
    });
    this.element.classList.remove('hidden');
  }
}