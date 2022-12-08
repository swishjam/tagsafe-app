class Logger {
  constructor(logs = '') {
    this.logs = logs;
  }

  log = (message, options = {}) => {
    console.log(message);
    this.logs += `
      <span class="log-line ${options.klass}" ${options.highlightKey ? 'data-highlight-key='+options.highlightKey : null }>
        <span class="timestamp">${this._currentDateTime()}> </span>
        <span class="log-message">${message}</span>
      </span>
    `
  }

  _currentDateTime() {
    let d = new Date();
    let hr = d.getHours();
    let min = d.getMinutes();
    let secs = d.getSeconds();
    if (min < 10) {
      min = "0" + min;
    }
    if(hr > 12) {
      hr -= 12;
    }
    return `${hr}:${min}:${secs}`;
  }
}

module.exports = Logger;