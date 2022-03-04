import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['video'];

  connect() {
    this.player = videojs(this.videoTarget, {
      controls: this.videoTarget.getAttribute('controls') === 'true',
      autoplay: this.videoTarget.getAttribute('data-autoplay'),
      fluid: true
    });
    this.player.on('timeupdate', _e => this._checkTimestampCallback(this.player.currentTime()) );
  }

  _checkTimestampCallback = currentTime => {
    // if()
  }
}