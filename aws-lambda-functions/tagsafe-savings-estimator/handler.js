const PerformanceMeasurer = require("./src/performanceMeasurer");
const TagHoster = require("./src/tagHoster");
const fs = require('fs');

require('dotenv').config();

module.exports.handle = async (event, _context) => {
  const { page_url, num_iterations = 3 } = event;
  let { first_party_urls = [] } = event;
  let knownFirstPartyHosts = ['cdn.shopify.com', 'shopifycdn.com', 'assets.shopify.com', 'assets.shopifycdn.com'];

  if(!page_url) {
    throw new Error(`Missing required param: \`page_url\`, received: ${JSON.stringify(event)}`);
  }

  const firstPartyHosts = first_party_urls.map(url => new URL(url).host).concat(new URL(page_url).host).concat(knownFirstPartyHosts);

  const tagHoster = new TagHoster({ pageUrl: page_url, firstPartyHosts });
  const { tagUrlsToTagsafeCDNMap, totalOriginalByteSize, totalMinifiedByteSize } = await tagHoster.findAllThirdPartyTagsAndUploadThemToS3();

  console.log(`Warming up tagsafe CDN...`);
  for(let [_tagUrl, tagsafeCDNUrl] of Object.entries(tagUrlsToTagsafeCDNMap)) {
    await fetch(tagsafeCDNUrl);
  }

  let withTagsafePerformanceMetrics = [];
  let withoutTagsafePerformanceMetrics = [];

  for(let i = 0; i < num_iterations; i++) {
    console.log(`Running iteration ${i + 1} of ${num_iterations}...`);
    const withTagsafePerformanceMeasurer = new PerformanceMeasurer({ pageUrl: page_url, tagUrlsToTagsafeCDNMap });
    const withoutTagsafePerformanceMeasurer = new PerformanceMeasurer({ pageUrl: page_url, tagUrlsToTagsafeCDNMap: {} });
    const [withTagsafePerformanceMetric, withoutTagsafePerformanceMetric] = await Promise.all([
      withTagsafePerformanceMeasurer.measurePerformance(),
      withoutTagsafePerformanceMeasurer.measurePerformance(),
    ])
    withTagsafePerformanceMetrics.push(withTagsafePerformanceMetric);
    withoutTagsafePerformanceMetrics.push(withoutTagsafePerformanceMetric);
  };

  const withTagsafeAverages = generateObjectAverages(withTagsafePerformanceMetrics);
  const withoutTagsafeAverages = generateObjectAverages(withoutTagsafePerformanceMetrics);

  const withTagsafeMedians = generateMedianValues(withTagsafePerformanceMetrics);
  const withoutTagsafeMedians = generateMedianValues(withoutTagsafePerformanceMetrics);

  await tagHoster.purgeUploadedThirdPartyTagsFromS3();

  const results = {
    tagUrlsToTagsafeCDNMap,
    numThirdPartyTags: Object.keys(tagUrlsToTagsafeCDNMap).length,
    totalOriginalByteSize,
    totalMinifiedByteSize,
    percentBytesSaved: (totalOriginalByteSize - totalMinifiedByteSize) / totalOriginalByteSize,
    withTagsafeAverages,
    withoutTagsafeAverages,
    averageTagsafeSavings: measureDiff(withTagsafeAverages, withoutTagsafeAverages),
    withTagsafeMedians,
    withoutTagsafeMedians,
    medianTagsafeSavings: measureDiff(withTagsafeMedians, withoutTagsafeMedians),
  };
  if(['collin-dev', 'local'].includes(process.env.NODE_ENV)) fs.writeFileSync(`${__dirname}/_results/${page_url.replace(/[^a-zA-Z0-9]/g, '')}-${Date.now()}.json`, JSON.stringify(results, null, 2));
  return results;
}

const measureDiff = (withTagsafe, withoutTagsafe) => {
  const diff = {};
  Object.keys(withTagsafe).forEach(key => {
    diff[key] = (withoutTagsafe[key] || 0) - (withTagsafe[key] || 0);
    diff[`${key}PercentSavings`] = `${(diff[key] / withoutTagsafe[key]) * 100}%`;
    diff
  });
  return diff;
}

const generateObjectAverages = objects => {
  const averages = {};
  Object.keys(objects[0]).forEach(key => {
    averages[key] = objects.map(obj => obj[key]).reduce((a, b) => a + b, 0) / objects.length;
  });
  return averages;
}

const generateMedianValues = objects => {
  const medians = {};
  Object.keys(objects[0]).forEach(key => {
    medians[key] = objects.map(object => object[key]).sort((a, b) => a - b)[Math.floor(objects.length / 2)];
  });
  return medians;
}