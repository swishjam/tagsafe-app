const PerformanceMeasurer = require("./src/performanceMeasurer");
const TagHoster = require("./src/tagHoster");

module.exports.handle = async (event, _context) => {
  const { page_url } = event;
  let { first_party_urls = [] } = event;

  if(!page_url) {
    throw new Error(`Missing required param: \`page_url\`, received: ${JSON.stringify(event)}`);
  }

  const firstPartyHosts = first_party_urls.map(url => new URL(url).host).concat(new URL(page_url).host);

  const tagHoster = new TagHoster({ pageUrl: page_url, firstPartyHosts });
  const tagUrlsToTagsafeCDNMap = await tagHoster.findAllThirdPartyTagsAndUploadThemToS3();

  const withTagsafePerformanceMeasurer = new PerformanceMeasurer({ pageUrl: page_url, tagUrlsToTagsafeCDNMap });
  const withTagsafePerformanceMetrics = await withTagsafePerformanceMeasurer.measurePerformance();

  // const withoutTagsafePerformanceMeasurer = new PerformanceMeasurer({ pageUrl: page_url, tagUrlsToTagsafeCDNMap: {} });
  // const withoutTagsafePerformanceMetrics = await withoutTagsafePerformanceMeasurer.measurePerformance();

  return {
    withTagsafePerformanceMetrics,
    // withoutTagsafePerformanceMetrics,
    // difference: measureDiff(withTagsafePerformanceMetrics, withoutTagsafePerformanceMetrics)
  };
}

const measureDiff = (withTagsafe, withoutTagsafe) => {
  const diff = {};
  Object.keys(withTagsafe).forEach(key => {
    diff[key] = (withoutTagsafe[key] || 0) - (withTagsafe[key] || 0);
  });
  return diff;
}
