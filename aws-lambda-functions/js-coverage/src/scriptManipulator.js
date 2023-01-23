module.exports = class ScriptManipulator {
  constructor({ page, urlPatternsToBlock, urlToInject, urlToInjectLoadStrategy }) {
    this.page = page;
    this.urlPatternsToBlock = urlPatternsToBlock;
    this.urlToInject = urlToInject;
    this.urlToInjectLoadStrategy = urlToInjectLoadStrategy;
  }

  async blockRequestsToUrlPatterns() {
    await this.page.setRequestInterception(true);
    this.page.on('request', async req => {
      if (
        req.resourceType() === 'script' && 
        this.urlPatternsToBlock.find(pattern => req.url().includes(pattern)) && 
        req.url() !== this.urlToInject
      ) {
        console.log(`Blocking request to ${req.url()}`);
        await req.abort();
      } else {
        await req.continue();
      }
    });
  }

  async injectScriptOnNewDocument() {
    await this.page.on('console', msg => {
      if(msg.text().startsWith('TAGSAFE_MSG::')) console.log(msg.text().split('TAGSAFE_MSG::')[1])
    })
    
    await this.page.evaluateOnNewDocument((tagUrlToInject, tagToInjectLoadStrategy) => {
      function tryToAddScriptToHead(scriptUrl, loadStrategy, attempts = 1) {
        if (window.self !== window.top) return;
        if (document.head) {
          console.log(`TAGSAFE_MSG::ADDING ${tagUrlToInject} TO THE DOM`);
          const script = document.createElement('script');
          if (tagToInjectLoadStrategy) script.setAttribute(tagToInjectLoadStrategy, '');
          script.setAttribute('src', tagUrlToInject);
          script.addEventListener('load', () => console.log(`TAGSAFE_MSG::${tagUrlToInject} has loaded!`));
          script.addEventListener('error', () => console.log(`TAGSAFE_MSG::${tagUrlToInject} has errored out!`));
          document.head.appendChild(script);
        } else if(attempts < 50) { // 5 seconds
          console.log(`TAGSAFE_MSG::Can't inject script, head is not present. Trying again...`);
          setTimeout(() => tryToAddScriptToHead(scriptUrl, loadStrategy, attempts + 1), 100);
        } else {
          console.error('Was unable to find the head of the document within 5 seconds.');
        }
      }
      tryToAddScriptToHead(tagUrlToInject, tagToInjectLoadStrategy);
    }, this.urlToInject, this.urlToInjectLoadStrategy);
  }
}