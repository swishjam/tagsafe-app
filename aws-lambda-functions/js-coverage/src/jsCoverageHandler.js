module.exports = class JsCoverageHandler {
  constructor(page, tagUrlPattern) {
    this.page = page;
    this.tagUrlPattern = tagUrlPattern;
  }

  async measureCoverage() {
    const allJsCoverage = await this.page.coverage.stopJSCoverage();
    const jsCoverageForTag = allJsCoverage.find(covObj => covObj.url.includes(this.tagUrlPattern));
    if (!jsCoverageForTag) throw Error(`Unable to find any JS for ${this.tagUrlPattern}`);
    return this._formatResults(jsCoverageForTag);
  }

  _formatResults(coverageResultsForTag) {
    let results = {
      jsUsedBytes: 0,
      totalJsBytes: coverageResultsForTag.text.length,
      percentJsUsed: 0,
      coveredJs: ""
    }
    console.log(coverageResultsForTag.rawScriptCoverage.functions)
    for (const range of coverageResultsForTag.ranges) {
      results.jsUsedBytes += range.end - range.start - 1;
      if(process.env.INCLUDE_RAW_JS_COVERAGE === 'true') results.coveredJs += coverageResultsForTag.text.slice(range.start, range.end) + "\n";
    }
    results.percentJsUsed = (results.jsUsedBytes / results.totalJsBytes) * 100;
    return results;
  }
}