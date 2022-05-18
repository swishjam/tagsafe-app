class Logger {
  constructor() {
    this.userLogs = ''
  }

  log = (logMsg, logKlass = '') => {
    let date = new Date();
    this.userLogs += `<span class="user-log ${logKlass}"><span class='user-log-timestamp'>${date.getMonth()+1}/${date.getDate()}/${date.getFullYear()} ${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}: </span><span class='user-log-message'>${logMsg}</span></span>`;
    console.log(`USER LOG: ${logMsg}`)
  }

  listenForPageLogs = page => {
    page.on('console', log => {
      if(log.text().startsWith('TAGSAFE_LOG::')) {
        const logParams = log.text().split('::');
        const logType = logParams[1];
        const logPayload = logParams[2];
        if(logType === 'USER_FACING_LOG')  {
          this.log(logPayload);;
        } else {
          console.log(`${logType}: ${logPayload}`);
        }
      }
    })
  }
}

module.exports = Logger;