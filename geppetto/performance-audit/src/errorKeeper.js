class ErrorKeeper {
  constructor(pageEventHandler) {
    this.pageEventHandler = pageEventHandler;
    this._failedNetworkRequests = [];
    this._pageUncaughtErrors = [];
    this._pageConsoleErrors = [];
    this._listenForErrors();
  }

  pageConsoleErrors = () => this._pageConsoleErrors;
  pageUncaughtErrors = () => this._pageUncaughtErrors;
  failedNetworkRequests = () => this._failedNetworkRequests;

  _listenForErrors = () => {
    this.pageEventHandler.on('CONSOLE_ERROR', logMsg => this._pageConsoleErrors.push(logMsg));
    this.pageEventHandler.on('FAILED_NETWORK_REQUEST', reqUrl => this._failedNetworkRequests.push(reqUrl));
    this.pageEventHandler.on('UNCAUGHT_ERROR', err => {
      this._pageUncaughtErrors.push(err)
    });
  }
}

module.exports = ErrorKeeper;