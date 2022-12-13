class ValidityChecker {
  constructor({ page, resourceKeeper, inflightRequests, ensureInjectedTagHasLoaded, throwErrorIfDOMCompleteIsZero = true }) {
    this.page = page;
    // this.pageManipulator = pageManipulator;
    this.resourceKeeper = resourceKeeper;
    this.inflightRequests = inflightRequests;
    this.ensureInjectedTagHasLoaded = ensureInjectedTagHasLoaded;
    this.throwErrorIfDOMCompleteIsZero = throwErrorIfDOMCompleteIsZero;
  }

  ensureAuditIsValid = async () => {
    console.log('Ensuring audit is valid...');
    await this._ensureAuditedTagsHaveLoaded();
    await this._ensureDomCompleteIsPositive();
    console.log('Passed validity check!');
  }

  _ensureAuditedTagsHaveLoaded = async () => {
    if(this.ensureInjectedTagHasLoaded) {
      try {
        console.log(`Ensuring injected tag has loaded........`);
        await this.page.waitForFunction('window.tagsafeInjectedTagLoaded');
        console.log(`Injected tag confirmed loaded! Continuing...`);
      } catch(err) {
        console.log(`Error encountered in _ensureAuditedTagsHaveLoaded: ${err}`);
        throw Error(`Audited tag never loaded.`);
      }
    }
  }

  _ensureDomCompleteIsPositive = async () => {
    try {
      console.log(`Ensuring DOM Complete is > 0...${this.throwErrorIfDOMCompleteIsZero ? 'going to' : 'not going to'} throw an error if it isnt...`);
      await this.page.waitForFunction('window.performance.getEntriesByType("navigation")[0].domComplete > 0');
      console.log(`DOM Complete is > 0! Continuing...`);
    } catch(err) {
      if(this.throwErrorIfDOMCompleteIsZero) {
        throw Error(await this._invalidDomCompleteMessage());
      } else {
        console.log(await this._invalidDomCompleteMessage());
      }
    }
  }

  _invalidDomCompleteMessage = async () => {
    const actualDomCompleteTime = await this.page.evaluate(() => performance.getEntriesByType('navigation')[0].domComplete);
    let msg = `DOM complete time is ${actualDomCompleteTime}, it must be greater than 0 for accurate performance measurements. `;
    // if(this.inflightRequests && this.inflightRequests.size > 0) {
    //   console.log(`DOM COMPLETE 0 HELPER: ${this.inflightRequests.size} requests went out and never responded, potentially causing DOM Complete to not finish: ${Array.from(this.inflightRequests).join(', ')}. `);
    // } else {
    //   console.log('DOM COMPLETE 0 HELPER: All requests have completed, but some resources are not becoming fully parsed/loaded. ');
    // }
    // if(this.resourceKeeper.resourcesWaitingToLoad().length > 0) {
    //   console.log(`DOM COMPLETE 0 HELPER: The following resources never completed loading, potentially causing DOM Complete to not complete: ${this.resourceKeeper.resourcesWaitingToLoad().join(', ')}. `);
    // }
    msg += 'Consider disabling images or other approaches to allow for the page to reach DOM Complete in a timely manner.'
    return msg;
  }
}

module.exports = ValidityChecker;