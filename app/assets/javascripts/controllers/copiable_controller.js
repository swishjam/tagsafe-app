import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['copyTextInput'];

  copyText() {
    this.copyTextInputTarget.select();
    navigator.clipboard.writeText(this.copyTextInputTarget.value);
    console.log('copied!');
  }
}