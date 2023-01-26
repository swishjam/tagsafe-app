export default class ErrorReporter {
  constructor({ reportingURL }) {
    this.reportingURL = reportingURL;
  }

  async reportError(error) {
    try {
      const response = await fetch('https://tagsafe-error-reporting.herokuapp.com/error', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          url: window.location.href,
          error: {
            message: error.message,
            stack: error.stack,
            name: error.name
          }
        })
      });
      if(response.status !== 200) {
        throw new Error(`Error reporting failed with status code ${response.status}`);
      }
    } catch(err) {
      console.error(`Error reporting failed with error: ${err.message}`);
    }
  }
}