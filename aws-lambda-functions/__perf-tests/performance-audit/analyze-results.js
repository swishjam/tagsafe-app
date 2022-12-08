const fs = require('fs');

const results1 = JSON.parse(fs.readFileSync(`./data/cantire/not-cached-with-tag/results-1.json`, 'utf8'));
const results2 = JSON.parse(fs.readFileSync(`./data/cantire/not-cached-with-tag/results-2.json`, 'utf8'));
const results3 = JSON.parse(fs.readFileSync(`./data/cantire/not-cached-with-tag/results-3.json`, 'utf8'));
const results4 = JSON.parse(fs.readFileSync(`./data/cantire/not-cached-with-tag/results-4.json`, 'utf8'));
const results5 = JSON.parse(fs.readFileSync(`./data/cantire/not-cached-with-tag/results-5.json`, 'utf8'));
const results = [results1, results2, results3, results4, results5];

function analyzeMetric(metricName) {
  const metrics = results.map(result => result['results'][metricName]).sort();
  const min = Math.min(...metrics);
  const max = Math.max(...metrics);
  const avg = metrics.reduce((partialSum, num) => partialSum+num, 0)/metrics.length;
  const diff = max - min;
  const variance = (diff / avg) * 100;
  const res = `===${metricName}===\nMin: ${min}\nMax: ${max}\nAvg: ${avg}\nVariance:${variance}%\n\n`
  console.log(res);
  fs.writeFileSync(`./data/tagsafe-io/cached-without-tag/analyzed.txt`, res);
}

analyzeMetric('DOMComplete');
analyzeMetric('DOMInteractive');
analyzeMetric('DOMContentLoaded');
analyzeMetric('FirstContentfulPaint');
analyzeMetric('Load');
analyzeMetric('TaskDuration');
analyzeMetric('ScriptDuration');
analyzeMetric('LayoutDuration');