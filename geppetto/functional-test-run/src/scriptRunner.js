const PuppeteerCallbackHandler = require('./puppeteerMethodCallbackHandler'),
        PuppeteerModerator = require('./puppeteerModerator');

require('dotenv').config();

class ScriptRunner {
  constructor({
    puppeteerScript, 
    expectedResults, 
    logger,
    screenRecorder,
    tagManipulator,
    exposedFunctionsHandler,
    domManipulator,
    options = {}
  }) {
    this.puppeteerScript = puppeteerScript;
    this.expectedResults = expectedResults;
    
    this.logger = logger;
    this.screenRecorder = screenRecorder;
    this.tagManipulator = tagManipulator;
    this.exposedFunctionsHandler = exposedFunctionsHandler;
    this.domManipulator = domManipulator;

    this.displayScriptFunctionsInRecording = true;
    this.maxScriptExecutionMs = options['maxScriptExecutionMs'] || 30_000;
    this.includeScreenRecordingOnPassingScript = options['includeScreenRecordingOnPassingScript'] || false;
    this.puppeteerSlowMoMs = parseInt(options['puppeteerSlowMoMs'] || process.env.DEFAULT_PUPPETEER_SLOW_MO_MS || 100);
    
    this.scriptResults;
    this.passed = false;
  }

  run = async () => {
    await this._setupPuppeteerForScriptRun();
    await this._preparePageForScriptRun();
    await Promise.race([
      this._runScript().catch(err => this._failed(err.message, err.stack)),
      this._returnErrorIfScriptExecutionTimeExceedsThreshold()
    ]);
    this._haultLambdaTimeout();
    this._disablePuppeteerMethodCallbacks();
    await this._passOrFailBasedOnScriptResults();
    await this._displayResultsOnPage();
    await this._stopAndUploadScreenRecordingIfNecessary();
    await this._killBrowser();
  }

  _returnErrorIfScriptExecutionTimeExceedsThreshold = () => {
    console.log(`Setting timeout to kill script execution ${this.maxScriptExecutionMs/1_000} seconds.`);
    // const executionTimeoutStartTime = Date.now();
    return new Promise(resolve => {
      this.lambdaTimeoutPromiseResolve = resolve;
      this.lambdaTimeoutSetTimeoutFunc = setTimeout(async () => {
        if(this.scriptIsRunning) {
          // not using because dont want to skew calculations of average execution time as this is not indicative because it gets cut short
          // this.scriptExecutionMs = Date.now() - executionTimeoutStartTime;
          const stalledFunction = this.callbackHandler.currentPuppeteerMethodInExecution
          if(stalledFunction) {
            // override any existing failures, which are unlikely if the script is still running
            this.scriptExceededThreshold = true;
            this._failed(`Script execution timed out after ${this.maxScriptExecutionMs/1_000} seconds while waiting for function \`${stalledFunction['functionName']}\` with argument(s) of: \`${stalledFunction['arguments']}\` to complete.`, null, true);
          } else {
            this._failed(`Script execution timed out after ${this.maxScriptExecutionMs/1_000} seconds.`, null, true);
          }
          this._haultLambdaTimeout();
        } else {
          console.log(`evaluating \`_returnErrorIfScriptExecutionTimeExceedsThreshold\` after ${this.maxScriptExecutionMs/1_000} seconds but script is not running, so not returning error...`);
          this._haultLambdaTimeout();
        }
      }, this.maxScriptExecutionMs);
    })
  }

  _haultLambdaTimeout = resolveData => {
    console.log('Haulting Lambda timeout...');
    if(!this.lambdaTimeoutResolved) {
      this.lambdaTimeoutResolved = true;
      console.log('Lambda timeout haulted...');
      clearTimeout(this.lambdaTimeoutSetTimeoutFunc);
      this.lambdaTimeoutPromiseResolve(resolveData);
    } else {
      console.log('Lambda timeout is already haulted, skipping...');
    }
  }

  _setupPuppeteerForScriptRun = async () => {
    console.log('Launching puppeteer...')
    this.puppeteerModerator = new PuppeteerModerator({ slowMoMs: this.puppeteerSlowMoMs });
    this.page = await this.puppeteerModerator.launch();
    this.logger.listenForPageLogs(this.page);
  }

  _preparePageForScriptRun = async () => {
    console.log('Preparing page for script run...');
    this.domManipulator.setPage(this.page);
    this.exposedFunctionsHandler.setPage(this.page);
    await this.tagManipulator.setUpTagManipulationForPage(this.page);
    await this.domManipulator.addInteractionsAmplifiers();
    await this.screenRecorder.startRecordingIfNecessary(this.page);
    this.scriptToRun = this.exposedFunctionsHandler.mountScriptAsCallableFunction(this.puppeteerScript);
    if(this.scriptToRun.toString() !== `async TS => {\n${this.puppeteerScript}\n}`) {
      console.error(`this.scriptToRun = \n\n${this.scriptToRun.toString()} \n\n but it should = \n\n async TS => { ${this.puppeteerScript} }\n\n`);
      throw Error('Unexpected error. Tagsafe is not referencing the correct provided script.');
    } else {
      console.log('Verified provided script is being referenced correctly.');
    }
    this._setPuppeeteerMethodCallbacks();
  }

  _runScript = async () => {
    let start = new Date();
    try {
      console.log(`Running provided script...`);
      this.scriptIsRunning = true;
      this.scriptResults = await this.scriptToRun(this.exposedFunctionsHandler);
      if(this.scriptResults) this.scriptResults = this.scriptResults.toString();
      this.scriptIsRunning = false;
      this.scriptExecutionMs = !this.scriptExceededThreshold ? this.scriptExecutionMs || Date.now() - start : null;
      console.log(`Script ran without error in ${this.scriptExecutionMs/1_000} seconds!`);
    } catch(err) {
      this.scriptIsRunning = false;
      this.scriptExecutionMs = !this.scriptExceededThreshold ? this.scriptExecutionMs || Date.now() - start : null;
      console.error(`Encountered error in provided script in ${(Date.now() - start)/1_000} seconds, error: ${err.message}`);
      this._failed(err.message, err.stack);
    }
  }

  _stopAndUploadScreenRecordingIfNecessary = async () => {
    if(!this.passed) {
      console.log('Stopping and uploading screen recording because the test failed.');
      await this.screenRecorder.tryToStopRecordingAndUploadToS3IfNecessary();
    } else if(this.includeScreenRecordingOnPassingScript) {
      console.log('Stopping and uploading screen recording even though the test passed.');
      await this.screenRecorder.tryToStopRecordingAndUploadToS3IfNecessary();
    } else {
      // this results in an error of `Error detaching session Session already detached. Most likely the page has been closed.` but the test still passes.
      console.log('Ignoring upload of screen recording because the test passed.');
    }
  }

  _passOrFailBasedOnScriptResults = async () => {
    if(!this.failureMessage) {
      if(this.expectedResults && this.expectedResults !== this.scriptResults) {
        this._failed(`Expected script to return '${this.expectedResults}' but instead got '${this.scriptResults}'`);
      } else if(this.expectedResults && this.expectedResults === this.scriptResults) {
        console.log(`Script returned '${this.scriptResults}' which is what we expected. Passing...`)
        this.passed = true;
      } else {
        console.log('No expected results defined. Passing...');
        this.passed = true;
      }
    } else {
      console.log(`Skipping _passOrFailBasedOnScriptResults because test already failed with ${this.failureMessage}`);
    }
  }

  _displayResultsOnPage = async (sleepMs = 1_500) => {
    console.log(`Queueing results to display in ${sleepMs/1_000} seconds...`);
    return new Promise(async resolve => {
      setTimeout(async () => {
        const msg = this.passed ? 'Test passed!' : `Test failed: ${this.failureMessage}`;
        console.log(`Appending message to DOM: ${msg}`);
        await this.domManipulator.displayResultsMessage({ success: this.passed, message: msg });
        setTimeout(resolve, 500) // wait another 500 ms of buffer time to resolve;
      }, sleepMs)
    })
  }

  _setPuppeeteerMethodCallbacks = () => {
    this.callbackHandler = new PuppeteerCallbackHandler(this.page);
    if(this.displayScriptFunctionsInRecording) {
      this.callbackHandler.setupCallbacks();
      this.callbackHandler.onPuppeteerFunctionCalled = this.domManipulator.displayFunctionCalledNotification;
      this.callbackHandler.onPuppeteerFunctionResponded = this.domManipulator.displayFunctionRespondedNotification;
    }
  }

  _disablePuppeteerMethodCallbacks = () => {
    this.callbackHandler.stopCallbacks();
  }

  _killBrowser = async () => {
    console.log('Removing script file from disk and shutting down puppeteer.');
    this.exposedFunctionsHandler.unMountScriptFile();
    await this.puppeteerModerator.shutdown();
  }

  _failed = (errMessage, errStack, overrideExistingErrors = false) => {
    if(!this.failureMessage || overrideExistingErrors) {
      console.error(`script failed: ${errStack || errMessage}`);
      this.passed = false;
      this.failureMessage = errMessage;
      this.failureStack = errStack;
    }
  }
}

module.exports = ScriptRunner;