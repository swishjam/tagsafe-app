const CreditWallet = require('../../test-helpers/factories/credit-wallet'),
        DataStoreManager = require('../../../../geppetto/release-monitoring/src/dataStoreManager'),
        DBConnecter = require('../../test-helpers/dbConnecter'),
        Domain = require('../../test-helpers/factories/domain'),
        GeneralConfiguration = require('../../test-helpers/factories/general-configuration'),
        SubscriptionPlan = require('../../test-helpers/factories/subscription-plan'),
        Tag = require('../../test-helpers/factories/tag'),
        TagPreference = require('../../test-helpers/factories/tag-preference');

DBConnecter.setUpTests();
const dataStore = new DataStoreManager;
let domain;
let tag;

beforeEach(async () => {
  domain = await Domain.create({ url: 'https://www.tagsafe.io' });
  tag = await Tag.create({ domain: domain });
})

describe('#getReleaseCheckConfigurationsForInterval', () => {
  test('Returns Tags with release monitoring enabled for this interval and no CreditWallet', async () => {
    const currentMinuteInterval = 5;
    
    await TagPreference.create({ tag: tag, releaseMonitoringInterval: currentMinuteInterval });
    await GeneralConfiguration.create({ parentId: domain.id, parentType: 'Domain', numRecentTagVersionsToCompareInReleaseMonitoring: 3 });
    const subscriptionPlan = await SubscriptionPlan.create({ domainId: domain.id });
    await domain.update({ currentSubscriptionPlan: subscriptionPlan });
    
    const releaseCheckConfigs = await dataStore.getReleaseCheckConfigurationsForInterval(currentMinuteInterval);
    
    expect(releaseCheckConfigs.length).toBe(1);
    expect(releaseCheckConfigs[0].tag_id).toBe(tag.id);
    expect(releaseCheckConfigs[0].tag_url).toBe(tag.fullUrl);
    expect(releaseCheckConfigs[0].release_check_minute_interval).toBe(currentMinuteInterval);
    expect(releaseCheckConfigs[0].current_hashed_content).toBe(null);
    expect(releaseCheckConfigs[0].current_version_bytes_size).toBe(null);
    expect(releaseCheckConfigs[0].marked_as_pending_tag_version_capture_at).toBe(null);
    expect(releaseCheckConfigs[0].num_recent_tag_versions_to_compare_in_release_monitoring).toBe(3);
    expect(releaseCheckConfigs[0].ten_most_recent_hashed_content).toBe("[null]");
  })
})