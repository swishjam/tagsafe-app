class PuppeteerMethodCallbackHandler {
  constructor(page) {
    this.page = page;
    this.functionCallCallbacks = {};
    this.responseCallbacks = {};
  }

  onFunctionCall = (funcName, callback) => {
    if(this.functionCallCallbacks[funcName]) {
      this.functionCallCallbacks[funcName].push(callback)
    } else {
      this.functionCallCallbacks[funcName] = [callback];
    }
  }

  onFunctionResponse = (funcName, callback) => {
    if(this.responseCallbacks[funcName]) {
      this.responseCallbacks[funcName].push(callback)
    } else {
      this.responseCallbacks[funcName] = [callback];
    }
  }

  setupCallbacks = () => {
    console.log('Monkey patching puppeteer functions....');
    this._asyncFunctionNamesToMonkeyPatch().forEach(this._monkeyPatchFunction);
    this.callbacksEnabled = true;
  }

  stopCallbacks = () => {
    this.callbacksEnabled = false;
  }

  _monkeyPatchFunction = pageFuncName => {
    const ogFunc = this.page[pageFuncName];
    this.page[pageFuncName] = async (...args) => {
      if(this._shouldBypassFunctionCallbacks(pageFuncName, args)) {
        return await ogFunc.apply(this.page, args);
      } else {
        this.currentPuppeteerMethodInExecution = { functionName: pageFuncName, arguments: args };
        await this._tryFunctionCalledCallback(pageFuncName, args);
        const resp = await ogFunc.apply(this.page, args);
        await this._tryFunctionRespondedCallback(pageFuncName, resp, args);
        this.currentPuppeteerMethodInExecution = null;
        return resp;
      }
    }
  }

  _tryFunctionCalledCallback = async (pageFuncName, args) => {
    if(this.callbacksEnabled && this.onPuppeteerFunctionCalled) {
      await this.onPuppeteerFunctionCalled(pageFuncName, args);
    }
  }

  _tryFunctionRespondedCallback = async (pageFuncName, response, args) => {
    if(this.callbacksEnabled && this.onPuppeteerFunctionResponded) {
      await this.onPuppeteerFunctionResponded(pageFuncName, response, args);
    }
  }

  _shouldBypassFunctionCallbacks = (pageFuncName, args) => {
    return pageFuncName === 'evaluate' && args.includes('bypass-function-notification');
  }

  // _runFunctionCallCallbacks = async (funcName, ...args) => {
  //   const callbacks = (this.functionCallCallbacks[funcName] || []).concat(this.functionCallCallbacks['*'] || []).concat(this.functionCallCallbacks['all'] || []);
  //   for(let i = 0; i < (callbacks || []).length; i++) {
  //     let callback = callbacks[i];
  //     if(callback.constructor === (async () => {}).constructor) {
  //       await callback(funcName, args);
  //     } else {
  //       callback(funcName, args);
  //     }
  //   }
  // }

  // _runResponseCallbacks = async (funcName, response, ...args) => {
  //   const callbacks = (this.responseCallbacks[funcName] || []).concat(this.responseCallbacks['*'] || []).concat(this.responseCallbacks['all'] || []);
  //   for(let i = 0; i < (callbacks || []).length; i++) {
  //     let callback = callbacks[i];
  //     if(callback.constructor === (async () => {}).constructor) {
  //       await callback(funcName, response, args);
  //     } else {
  //       callback(funcName, response, args);
  //     }
  //   }
  // }

  _asyncFunctionNamesToMonkeyPatch = () => {
    return [
      '$',
      '$$',
      '$$',
      '$eval',
      '$x',
      'addScriptTag',
      'addStyleTag',
      'authenticate',
      'bringToFront',
      'click',
      'close',
      'content',
      'cookies',
      'createPDFStream',
      'deleteCookie',
      'emulate',
      'emulateCPUThrottling',
      'emulateIdleState',
      'emulateMediaFeatures',
      'emulateMediaType',
      'emulateNetworkConditions',
      'emulateTimezone',
      'emulateVisionDeficiency',
      'evaluate',
      'evaluateHandle',
      'evaluateOnNewDocument',
      'exposeFunction',
      'focus',
      'goBack',
      'goForward',
      'goto',
      'hover',
      'metrics',
      'pdf',
      'queryObjects',
      'reload',
      'screenshot',
      'select',
      'setBypassCSP',
      'setCacheEnabled',
      'setContent',
      'setCookie',
      'setDragInterception',
      'setExtraHTTPHeaders',
      'setGeolocation',
      'setJavaScriptEnabled',
      'setOfflineMode',
      'setRequestInterception',
      'setUserAgent',
      'setViewport',
      'tap',
      'title',
      'type',
      'waitFor',
      'waitForFileChooser',
      'waitForFrame',
      'waitForFunction',
      'waitForNavigation',
      'waitForNetworkIdle',
      'waitForRequest',
      'waitForResponse',
      'waitForSelector',
      'waitForTimeout',
      'waitForXPath',
    ]
  }

  // _synchronousFunctionNamesToMonkeyPatch = () => {
  //   return [
  //     'browser',
  //     'browserContext',
  //     'frames',
  //     'isClosed',
  //     'isDragInterceptionEnabled',
  //     'isJavaScriptEnabled',
  //     'mainFrame',
  //     'setDefaultNavigationTimeout',
  //     'setDefaultTimeout',
  //     'target',
  //     'url',
  //     'viewport',
  //     'workers'
  //   ]
  // }
}

module.exports = PuppeteerMethodCallbackHandler;