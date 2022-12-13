module.exports = class JsCoverageHandler {
  constructor(page, tagUrlToCalculateCoverage) {
    this.page = page;
    this.tagUrlToCalculateCoverage = tagUrlToCalculateCoverage;
  }

  async measureCoverage() {
    const allJsCoverage = await this.page.coverage.stopJSCoverage();
    const jsCoverageForTag = allJsCoverage.find(covObj => covObj.url === this.tagUrlToCalculateCoverage);
    if(!jsCoverageForTag) throw Error(`Unable to find JS Coverage for ${this.tagUrlToCalculateCoverage}`);
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
      results.coveredJs += coverageResultsForTag.text.slice(range.start, range.end) + "\n";
    }
    results.percentJsUsed = (results.jsUsedBytes / results.totalJsBytes) * 100;
    return results;
  }
}