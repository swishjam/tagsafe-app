class PageEventHandler {
  constructor(page) {
    this.page = page;
    this.eventCallbacks = {
      CONSOLE_ERROR: [],
      DOM_CONTENT_LOADED_EVENT: [],
      EXPECT_RESOURCE_TO_LOAD: [],
      FAILED_NETWORK_REQUEST: [],
      INJECTED_TAG_ERROR: [
        tagUrl => { throw new Error(`Error loading injected tag ${tagUrl}`) }
      ],
      INJECTED_TAG_LOADED: [],
      LOAD_EVENT: [],
      LOG: [() => {}],
      LONG_RUNNING_TASK: [],
      REQUEST_CACHED: [],
      REQUEST_NOT_CACHED: [],
      RESOURCE_BLOCKED: [],
      RESOURCE_FAILED_TO_LOAD: [],
      RESOURCE_LOADED: [],
      THIRD_PARTY_TAG_ALLOWED: [],
      UNCAUGHT_ERROR: [],
      WEB_VITALS_CLS: [],
      WEB_VITALS_FID: [],
      WEB_VITALS_LCP: []
    };
    this._listenForTagsafeLogEvents();
  }

  emit = async (eventName, ...callbackArgs) => {
    const callbacks = this.eventCallbacks[eventName];
    for(let i = 0; i < callbacks.length; i++) {
      console.log(`\`PageEventHandler\` Event - ${eventName}: ${callbackArgs}`);
      await callbacks[i](...callbackArgs);
    };
  }

  on = (eventName, callback) => {
    if(!this.eventCallbacks[eventName]) throw Error(`Invalid PageLogHandler event: ${eventName}, valid events are ${Object.keys(this.eventCallbacks).join(', ')}`);
    this.eventCallbacks[eventName].push(callback);
  }

  _listenForTagsafeLogEvents() {
    this.page.on('console', async log => {
      if((log.text() || '').startsWith('TAGSAFE_LOG_EVENT::')) {
        const splitLog = log.text().split('::');
        const event = splitLog[1];
        const args = splitLog.slice(2);
        await this.emit(event, ...args);
      }
      if(log.type() === 'error') {
        await this.emit('CONSOLE_ERROR', log.text());
      }
    });
    this.page.on('pageerror', async err => await this.emit('UNCAUGHT_ERROR', err));
  }
}

module.exports = PageEventHandler;