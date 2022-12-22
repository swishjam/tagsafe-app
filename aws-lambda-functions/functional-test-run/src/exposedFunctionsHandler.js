const fs = require('fs');

class ExposedFunctionsHandler {
  constructor({ logger, urlsToWaitFor, filenamePrefix }) {
    this.logger = logger;
    this.urlsToWaitFor = urlsToWaitFor;
    this.scriptFileLocation = `/tmp/${filenamePrefix}-callableScript-${parseInt(Math.random()*1000000000)}.js`;
  }

  LOG = msg => {
    this.logger.log(msg);
  };

  WAIT_FOR_TAG = async () => {
    if(this.urlsToWaitFor.length > 0) {
      let startTime = Date.now();
      console.log('Ensuring Tagsafe injected tags have loaded with `WAIT_FOR_TAG` function...');
      try {
        // hard code for now, when we have many Tags to wait for we should make the function defined 
        // on tag load specific for each tag and then wait for each function here
        await this.PAGE.waitForFunction('window.tagsafeInjectedTagLoaded', { timeout: 0 });
        console.log(`Tagsafe injected tags have loaded after waiting ${(Date.now() - startTime)/1000} seconds, continuing...`);
      } catch(e) {
        throw Error(`Tagsafe injected tag never loaded after waiting ${(Date.now() - startTime)/1000} seconds.`)
      }
    }
  }

  setPage = page => {
    this.PAGE = page;
  }

  mountScriptAsCallableFunction = script => {
    console.log('Mounting provided script as a module');
    fs.writeFileSync(this.scriptFileLocation, `module.exports = async TS => {\n${script}\n}`);
    const scriptAsFunction = require(this.scriptFileLocation);
    return scriptAsFunction;
  }

  unMountScriptFile = () => {
    fs.unlinkSync(this.scriptFileLocation);
  }
}

module.exports = ExposedFunctionsHandler;