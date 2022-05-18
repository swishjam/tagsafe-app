const CreditWallet = require('../../test-helpers/factories/credit-wallet'),
        DataStoreManager = require('../../../../geppetto/uptime-monitoring/src/dataStoreManager'),
        DBConnecter = require('../../test-helpers/dbConnecter'),
        Domain = require('../../test-helpers/factories/domain'),
        SubscriptionPlan = require('../../test-helpers/factories/subscription-plan'),
        Tag = require('../../test-helpers/factories/tag'),
        UptimeRegion = require('../../test-helpers/factories/uptime-region'),
        UptimeRegionToCheck = require('../../test-helpers/factories/uptime-region-to-check');

DBConnecter.setUpTests();
const dataStore = new DataStoreManager;
let domain;
let tag;

beforeEach(async () => {
  domain = await Domain.create({ url: 'https://www.tagsafe.io' });
  tag = await Tag.create({ domain: domain });
})

describe('#getTagUptimeConfigurationsForRegion', () => {
  test('Returns Tags with uptime monitoring enabled for this region and no CreditWallet', async () => {
    process.env.AWS_REGION = 'us-east-1';
    
    const subscriptionPlan = await SubscriptionPlan.create({ domainId: domain.id });
    const uptimeRegion = await UptimeRegion.create({ regionName: 'us-east-1', location: 'US East (N Virginia)' });
    await UptimeRegionToCheck.create({ uptimeRegion: uptimeRegion, tag: tag });
    await domain.update({ currentSubscriptionPlan: subscriptionPlan });
    
    const uptimeConfigs = await dataStore.getTagUptimeConfigurationsForRegion();
    expect(uptimeConfigs.length).toBe(1);
    expect(uptimeConfigs[0].tag_id).toBe(tag.id);
    expect(uptimeConfigs[0].tag_url).toBe(tag.fullUrl);
    expect(uptimeConfigs[0].uptime_region_id).toBe(uptimeRegion.id);
  })

  test('Returns Tags with uptime monitoring enabled for this region and a CreditWallet with credits remaining', async () => {
    process.env.AWS_REGION = 'us-east-1';
    
    const subscriptionPlan = await SubscriptionPlan.create({ domainId: domain.id });
    const uptimeRegion = await UptimeRegion.create({ regionName: 'us-east-1', location: 'US East (N Virginia)' });
    await UptimeRegionToCheck.create({ uptimeRegion: uptimeRegion, tag: tag });
    await domain.update({ currentSubscriptionPlan: subscriptionPlan });
    await CreditWallet.create({ domain: domain, totalCreditsForMonth: 1_000, creditsRemaining: 10, creditsUsed: 990 });
    
    const uptimeConfigs = await dataStore.getTagUptimeConfigurationsForRegion();
    expect(uptimeConfigs.length).toBe(1);
    expect(uptimeConfigs[0].tag_id).toBe(tag.id);
    expect(uptimeConfigs[0].tag_url).toBe(tag.fullUrl);
    expect(uptimeConfigs[0].uptime_region_id).toBe(uptimeRegion.id);
  })

  test('Doesnt return Tags with uptime monitoring enabled for this region but a CreditWallet with 0 credits remaining', async () => {
    process.env.AWS_REGION = 'us-east-1';
    
    const subscriptionPlan = await SubscriptionPlan.create({ domainId: domain.id });
    const uptimeRegion = await UptimeRegion.create({ regionName: 'us-east-1', location: 'US East (N Virginia)' });
    await UptimeRegionToCheck.create({ uptimeRegion: uptimeRegion, tag: tag });
    await domain.update({ currentSubscriptionPlan: subscriptionPlan });
    await CreditWallet.create({ domain: domain, totalCreditsForMonth: 1_000, creditsRemaining: 0, creditsUsed: 1_000 });
    
    const uptimeConfigs = await dataStore.getTagUptimeConfigurationsForRegion();
    expect(uptimeConfigs.length).toBe(0);
  })

  test('Doesnt return Tags with uptime monitoring enabled for this region but a canceled SubscriptionPlan', async () => {
    process.env.AWS_REGION = 'us-east-1';
    
    const subscriptionPlan = await SubscriptionPlan.create({ domainId: domain.id, status: 'canceled' });
    const uptimeRegion = await UptimeRegion.create({ regionName: 'us-east-1', location: 'US East (N Virginia)' });
    await UptimeRegionToCheck.create({ uptimeRegion: uptimeRegion, tag: tag });
    await domain.update({ currentSubscriptionPlan: subscriptionPlan });
    await CreditWallet.create({ domain: domain, totalCreditsForMonth: 1_000, creditsRemaining: 1_000, creditsUsed: 0 });
    
    const uptimeConfigs = await dataStore.getTagUptimeConfigurationsForRegion();
    expect(uptimeConfigs.length).toBe(0);
  })

  test('Doesnt return Tags with uptime monitoring in a different region', async () => {
    process.env.AWS_REGION = 'us-east-2';
    
    const subscriptionPlan = await SubscriptionPlan.create({ domainId: domain.id, status: 'canceled' });
    const uptimeRegion = await UptimeRegion.create({ regionName: 'us-east-1', location: 'US East (N Virginia)' });
    await UptimeRegionToCheck.create({ uptimeRegion: uptimeRegion, tag: tag });
    await domain.update({ currentSubscriptionPlan: subscriptionPlan });
    await CreditWallet.create({ domain: domain, totalCreditsForMonth: 1_000, creditsRemaining: 1_000, creditsUsed: 0 });
    
    const uptimeConfigs = await dataStore.getTagUptimeConfigurationsForRegion();
    expect(uptimeConfigs.length).toBe(0);
  })
})