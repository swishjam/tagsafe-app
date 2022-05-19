'use strict';

const DataStoreManager = require('./src/dataStoreManager'),
        UptimeCheckRunner = require('./src/uptimeCheckRunner'),
        UptimeCheckConfig = require('./src/uptimeCheckConfig'),
        UptimeCheckResults = require('./src/uptimeCheckResults'),
        crypto = require('crypto'),
        newrelic = require('newrelic');

module.exports.checkTagsForUptime = async (event, context) => {
  console.log(`Running uptime check in ${process.env.AWS_REGION}.`);
  const batchUid = [1,2,3,4].map(() => crypto.randomBytes(2).toString('hex')).join('-');
  context.serverlessSdk.tagEvent('batch-uid', batchUid);
  newrelic.recordCustomEvent('batch-uid', { uid: batchUid });
  const startTs = Date.now();
  
  const dataStore = new DataStoreManager();
  const uptimeConfigurationsForRegion = await dataStore.getTagUptimeConfigurationsForRegion();
  
  const results = [];
  const numTags = uptimeConfigurationsForRegion.length;

  console.log(`Checking uptime for ${numTags} tags that are configured for the ${process.env.AWS_REGION} region.`);
  for(let i = 0; i < uptimeConfigurationsForRegion.length; i++) {
    const tagUptimeData = uptimeConfigurationsForRegion[i];
    
    const uptimeCheckConfig = new UptimeCheckConfig({ 
      tagId: tagUptimeData.tag_id, 
      tagUrl: tagUptimeData.tag_url,
      uptimeRegionId: tagUptimeData.uptime_region_id
    });
    const uptimeCheckRunner = new UptimeCheckRunner({ uptimeCheckConfig: uptimeCheckConfig, tagEvent: context.serverlessSdk.tagEvent, span: context.serverlessSdk.span });
    await uptimeCheckRunner.runUptimeCheck();
    
    results.push(uptimeCheckConfig)
  }

  const uptimeBatchId = await dataStore.createUptimeBatch({ 
    batchUid: batchUid, 
    numTagsChecked: numTags, 
    executedAt: DataStoreManager.formattedTs(startTs), 
    msToRunCheck: Date.now() - startTs 
  });

  if(results.length > 0) {
    const formattedResults = new UptimeCheckResults(uptimeBatchId, results).formattedForInsert();
    await dataStore.insertUptimeResults(formattedResults);
  }

  console.log('============================================')
  console.log(`==== Complete Uptime Monitoring batch! ====`);
  console.log(`====           Tags checked: ${numTags}          ====`);
  console.log('============================================')
  return results;
};