'use strict';

const PagePerformanceMeasurer = require('./src/pagePerformanceMeasurer');
const NetworkAnalyzer = require('./src/networkAnalyzer');
const fs = require('fs');
const { removeListener } = require('process');

require('dotenv').config();

module.exports.handle = async (event, _context) => {
  const { 
    page_url, 
    navigation_wait_until = 'networkidle2',
    first_party_urls = [page_url]
  } = event;

  const urls = [
    // ['https://www.eightsleep.com']
    // ['http://www.pourri.com', null],
    // ['http://www.pourri.com', null],
    // ['http://www.pourri.com', null],
    // ['http://www.pourri.com', null],
    // ['http://www.pourri.com', null],
    // ['http://www.12news.com', null],
    // ['http://www.4patriots.com', null],
    // ['http://www.national.aaa.com', null],
    // ['http://www.aaanationalusa.com', null],
    // ['http://www.aaaohio.com', null],
    // ['http://www.alabamamediagroup.com', null],
    // ['http://www.ahs.com', null],
    // ['http://www.americanpest.net', null],
    // ['http://www.anchorhocking.com', null],
    // ['http://www.anker.com', null],
    // ['http://www.azpbs.org', null],
    // ['http://www.blueskiesoftexas.org', null],
    // ['http://www.boardroomstylinglounge.com', null],
    // ['http://www.broadcastmed.com', null],
    // ['http://www.candle-lite.com', null],
    // ['http://www.carpettech.com', null],
    // ['http://www.clutter.com', null],
    // ['http://www.dentalwhale.com', null],
    // ['http://www.disa.com', null],
    // ['http://www.douglasj.com', null],
    // ['http://www.dentalbilling.com', null],
    // ['http://www.klove.com', null],
    // ['http://www.eightsleep.com', null],
    // ['http://www.facefoundrie.com', null],
    // ['http://www.fhiaremodeling.com', null],
    // ['http://www.frontdoorhome.com', null],
    // ['http://www.goettl.com', null],
    // ['http://www.hellobello.com', null],
    // ['http://www.hello-sunshine.com', null],
    // ['http://www.hellotech.com', null],
    // ['http://www.happyhiller.com', null],
    // ['http://www.horizonservices.com', null],
    // ['http://www.huberwood.com', null],
    // ['http://www.imaginecommunications.com', null],
    // ['http://www.inventhelp.com', null],
    // ['http://www.johnmooreservices.com', null],
    // ['http://www.kare11.com', null],
    // ['http://www.khou.com', null],
    // ['http://www.ksdk.com', null],
    // ['http://www.9news.com', null],
    // ['http://www.lawndoctorfranchise.com', null],
    // ['http://www.lifepharm.com', null],
    // ['http://www.littlegiantladders.com', null],
    // ['http://www.metamap.com', null],
    ['http://www.molekule.com', 'https://molekule.com'],
    // ['http://www.neatmethod.com', null],
    // ['http://www.neatmethod.com', null],
    // ['http://www.newwavecom.com', null],
    // ['http://www.nozzlenolen.com', null],
    // ['http://www.nozzlenolen.com', null],
    // ['http://www.oilchangers.com', null],
    // ['http://www.pbsdistribution.org', null],
    // ['http://www.newshour.org', null],
    // ['http://www.pigtailsandcrewcuts.com', null],
    // ['http://www.populationmedia.org', null],
    // ['http://www.razor.com', null],
    // ['http://www.razor.com', null],
    // ['http://www.razor.com', null],
    // ['http://www.red.com', null],
    // ['http://www.red.com', null],
    // ['http://www.red.com', null],
    // ['http://www.red.com', null],
    // ['http://www.reliableair.com', null],
    // ['http://www.rightnowmedia.org', null],
    // ['http://www.shopyourway.com', null],
    // ['http://www.shopyourway.com', null],
    // ['http://www.shopyourway.com', null],
    // ['http://www.shopyourway.com', null],
    // ['http://www.shophq.com', null],
    // ['http://www.evine.com', null],
    // ['http://www.solasalonstudios.com', null],
    // ['http://www.solasalonstudios.com', null],
    // ['http://www.hellosuper.com', null],
    // ['http://www.hellosuper.com', null],
    // ['http://www.surya.com', null],
    // ['http://www.surya.com', null],
    // ['http://www.tawkify.com', null],
    // ['http://www.tawkify.com', null],
    // ['http://www.tct.tv', null],
    // ['http://www.thelashlounge.com', null],
    // ['http://www.thelashlounge.com', null],
    // ['http://www.maids.com', null],
    // ['http://www.thermacell.com', null],
    // ['http://www.thermacell.com', null],
    // ['http://www.thermacell.com', null],
    // ['http://www.thermacell.com', null],
    // ['http://www.tricoci.com', null],
    // ['http://www.tricoci.com', null],
    // ['http://www.tricoci.com', null],
    // ['http://www.tricoci.com', null],
    // ['http://www.tricoci.com', null],
    // ['http://www.turnerpest.com', null],
    // ['http://www.tvunetworks.com', null],
    // ['http://www.tvunetworks.com', null],
    // ['http://www.tvunetworks.com', null],
    // ['http://www.tvunetworks.com', null],
    // ['http://www.tvunetworks.com', null],
    // ['http://www.tvunetworks.com', null],
    // ['http://www.twr.org', null],
    // ['http://www.10tv.com', null],
    // ['http://www.wfuv.org', null],
    // ['http://www.wkyc.com', null],
    // ['http://www.wral.com', null],
    // ['http://www.wthr.com', null],
    // ['http://www.wtsp.com', null],
    // ['http://www.wusa9.com', null],
    // ['http://www.wwltv.com', null],
    // ['http://www.yogibo.com', null],
    // ['http://www.youvegotmaids.com', null],
    // ['http://www.yupptv.com', null],
    // ['http://www.yupptv.com', null]
  ]

  for(let i = 0; i < urls.filter(onlyUnique).length; i++) {
    const url = urls[i][0];
    try {
      const providedFirstPartyUrls = urls[i][1] ? typeof urls[i][1] === 'string' ? [url, urls[i][1]] : [url, ...urls[i][1]] : [url];
      const knownFirstPartyUrls = ['https://cdn.shopify.com', 'https://productreviews.shopifycdn.com'];
      providedFirstPartyUrls.concat(knownFirstPartyUrls);
      const firstPartyUrls = providedFirstPartyUrls.concat(knownFirstPartyUrls);
      console.log(`Analyzing third party impact to ${url} (first party URLs = ${firstPartyUrls.join(', ')})`);
  
      const [perfResults, dns] = await Promise.all([
        PagePerformanceMeasurer.measureThirdPartyImpact(url, firstPartyUrls),
        NetworkAnalyzer.analyzeNetworkRequests(url, firstPartyUrls),
      ])
  
      fs.writeFileSync(`./results/${new URL(url).hostname.replace(/\/|\.|\:/g, '_')}-results.json`, JSON.stringify({ ...perfResults, ...dns }, null, 2));
      console.log(`Finished analyzing third party impact to ${url} (first party URLs = ${firstPartyUrls.join(', ')})`);
    } catch(err) {
      console.log(`Can't generate 3p impact for ${url}: ${err}`);
    }
  }
  console.log('DONE!');
  return;
  // return { perfResults, dns };
}

function onlyUnique(value, index, self) {
  return self.indexOf(value) === index;
}