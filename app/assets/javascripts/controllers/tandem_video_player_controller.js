import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [
    'playBtn', 'pauseBtn', 'rePlayBtn',
    'withTagVideoPlayer', 'withoutTagVideoPlayer', 'withTagVideoTimer', 'withoutTagVideoTimer',
    'dom_completeWithTagVisual', 'dom_interactiveWithTagVisual', 'first_contentful_paintWithTagVisual', 'dom_content_loadedWithTagVisual', 'script_durationWithTagVisual', 'task_durationWithTagVisual', 'layout_durationWithTagVisual',
    'dom_completeWithoutTagVisual', 'dom_interactiveWithoutTagVisual', 'first_contentful_paintWithoutTagVisual', 'dom_content_loadedWithoutTagVisual', 'script_durationWithoutTagVisual', 'task_durationWithoutTagVisual', 'layout_durationWithoutTagVisual'
  ];
  playingPlayers = [];
  pausedPlayers = [this.withTagVideoPlayer.id(), this.withoutTagVideoPlayer.id()];

  get withTagVideoPlayer() {
    return  this.cachedWithTagVideoPlayer = this.cachedWithTagVideoPlayer || videojs(this.withTagVideoPlayerTarget, { fluid: true, controls: false, poster: '#' });
  }

  get withoutTagVideoPlayer() {
    return this.cachedWithoutTagVideoPlayer = this.cachedWithoutTagVideoPlayer || videojs(this.withoutTagVideoPlayerTarget, { fluid: true, controls: false, poster: '#' });
  }

  // get videoPlayers() {
  //   return [this.withoutTagVideoPlayer, this.withoutTagVideoPlayer]
  // }

  connect() {
    this._setTimestampCallbacks();
    this._setOnPlayerTimeUpdatedListeners();
    this._setOnEndListeners();
  }

  playAllVideos() {
    this.playBtnTarget.classList.add('hidden');
    this.rePlayBtnTarget.classList.add('hidden');
    this.pauseBtnTarget.classList.remove('hidden');
    this._playPlayer(this.withTagVideoPlayer);
    this._playPlayer(this.withoutTagVideoPlayer);
  }

  replayAllVideos() {
    this._setTimestampCallbacks();
    this.playAllVideos();
  }

  pauseAllVideos() {
    this.playBtnTarget.classList.remove('hidden')
    this.rePlayBtnTarget.classList.add('hidden');
    this.pauseBtnTarget.classList.add('hidden');
    this._pausePlayer(this.withTagVideoPlayer);
    this._pausePlayer(this.withoutTagVideoPlayer);
  }

  updatePlaybackRate(e) {
    let previousSelectedRateEl = e.target.parentElement.querySelector('.active');
    previousSelectedRateEl.classList.add('outline');
    previousSelectedRateEl.classList.remove('active');
    e.target.classList.add('active');
    e.target.classList.remove('outline');
    let rate = parseFloat(e.target.getAttribute('data-rate'));
    this.withTagVideoPlayer.playbackRate(rate);
    this.withoutTagVideoPlayer.playbackRate(rate);
  }

  _playPlayer(player) {
    let index = this.pausedPlayers.indexOf(player.id());
    this.pausedPlayers.splice(index, 1);
    this.playingPlayers.push(player.id());
    player.play();
  }

  _pausePlayer(player) {
    let index = this.playingPlayers.indexOf(player.id());
    this.playingPlayers.splice(index, 1);
    this.pausedPlayers.push(player.id());
    player.pause();
  }

  _setTimestampCallbacks() {
    this.withTagTimestampCallbacks = JSON.parse(this.withTagVideoPlayerTarget.getAttribute('data-timestamp-callbacks') || '[]');
    this.withoutTagTimestampCallbacks = JSON.parse(this.withoutTagVideoPlayerTarget.getAttribute('data-timestamp-callbacks') || '[]');
  }

  _setOnPlayerTimeUpdatedListeners() {
    this.withTagVideoPlayer.on('timeupdate', _e => {
      let currentTime = this.withTagVideoPlayer.currentTime();
      this.withTagVideoTimerTarget.textContent = `${parseFloat(currentTime).toFixed(2)} s`;
      this._checkToRunCallbackForTimestamp({ callbacksArray: this.withTagTimestampCallbacks, currentTimestamp: currentTime, withTag: true });
    })
    this.withoutTagVideoPlayer.on('timeupdate', _e => {
      let currentTime = this.withTagVideoPlayer.currentTime();
      this.withoutTagVideoTimerTarget.textContent = `${parseFloat(currentTime).toFixed(2)} s`;
      this._checkToRunCallbackForTimestamp({ callbacksArray: this.withoutTagTimestampCallbacks, currentTimestamp: currentTime, withTag: false });
    })
  }

  _checkToRunCallbackForTimestamp({ callbacksArray, currentTimestamp, withTag }) {
    callbacksArray.forEach((callbackMetricAndTimestamp, i) => {
      // if the new timestamp is within 0.25 seconds of one of the callbacks, or if its past 
      // the callback timestamp, display the callback event
      let callbackTimestampSeconds = callbackMetricAndTimestamp.timestamp/1000;
      // let currentTimestampIsWithinQuarterOfASecondOfCallbackTimestamp = callbackTimestampSeconds - currentTimestamp < 0.25;
      let currentTimestampIsWithinQuarterOfASecondOfCallbackTimestamp = false;
      let currentTimestampIsGreaterThanCallbackTimestamp = currentTimestamp > callbackTimestampSeconds;
      if(currentTimestampIsWithinQuarterOfASecondOfCallbackTimestamp || currentTimestampIsGreaterThanCallbackTimestamp) {
        callbacksArray.splice(i, 1);
        this._progressPerformanceMetricVisualToTimestamp({ metric: callbackMetricAndTimestamp.metric, timestampSeconds: callbackTimestampSeconds, withTag: withTag, completed: true });
      } else {
        this._progressPerformanceMetricVisualToTimestamp({ metric: callbackMetricAndTimestamp.metric, timestampSeconds: currentTimestamp, withTag: withTag });
      }
    })
  }

  _progressPerformanceMetricVisualToTimestamp({ metric, timestampSeconds, withTag, completed = false }) {
    this.maxTimestampMs = this.maxTimestampMs || parseFloat(this.element.querySelector('.video-performance-progress-visuals-container').getAttribute('data-max-timestamp-ms'));
    let targetIdentifier = withTag ? `${metric}WithTagVisualTarget` : `${metric}WithoutTagVisualTarget`;
    this[targetIdentifier].style.width = `${(timestampSeconds/(this.maxTimestampMs/1000))*100}%`;
    if(completed) {
      this[targetIdentifier].classList.add('completed');
      this[targetIdentifier].classList.remove('running');
    } else {
      this[targetIdentifier].classList.add('running');
      this[targetIdentifier].classList.remove('completed');
    }
  }

  _setOnEndListeners() {
    this.withTagVideoPlayer.on('ended', () => this._onPlayerEnded(this.withTagVideoPlayer));
    this.withoutTagVideoPlayer.on('ended', () => this._onPlayerEnded(this.withoutTagVideoPlayer));
  }

  _onPlayerEnded(player) {
    this.pausedPlayers.push(player.id());
    let index = this.playingPlayers.indexOf(player.id());
    this.playingPlayers.splice(index, 1);
    if(this.playingPlayers.length === 0) {
      this._onAllPlayersEnded();
    }
  }

  _onAllPlayersEnded() {
    this.playBtnTarget.classList.add('hidden');
    this.pauseBtnTarget.classList.add('hidden');
    this.rePlayBtnTarget.classList.remove('hidden');
  }
}