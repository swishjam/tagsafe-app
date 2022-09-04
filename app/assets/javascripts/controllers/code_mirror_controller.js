import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['codeMirrorTextarea'];
  disableLineNumbers = this.codeMirrorTextareaTarget.getAttribute('data-disable-line-numbers') === 'true';
  readOnly = this.codeMirrorTextareaTarget.getAttribute('data-readonly') === 'true' ? 'nocursor' : false;
  wrapLines = this.codeMirrorTextareaTarget.getAttribute('data-dont-wrap-lines') !== 'true';

  connect() {
    this.codeMirrorInstance = CodeMirror.fromTextArea(this.codeMirrorTextareaTarget, { 
      lineNumbers: !this.disableLineNumbers,
      styleActiveLine: true,
      matchBrackets: true,
      readOnly: this.readOnly,
      lineWrapping: this.wrapLines
    });
    if(this.codeMirrorTextareaTarget.getAttribute('data-value')) {
      this.codeMirrorInstance.setValue(this.codeMirrorTextareaTarget.getAttribute('data-value').replace(/\\r\\n/g, '\r\n'));
    }
    this.codeMirrorTextareaTarget.classList.remove('hidden');
  }

  copyContent() {
    this.codeMirrorTextareaTarget.select();
    navigator.clipboard.writeText(this.codeMirrorTextareaTarget.value);
    this.element.classList.add('tagsafe-illuminate');
    setTimeout(() => this.element.classList.remove('tagsafe-illuminate'), 5000);
  }
}