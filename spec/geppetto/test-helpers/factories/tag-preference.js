const Factory = require('./factory'),
      DBConnecter = require('../dbConnecter');

module.exports = class TagPreference extends Factory {
  constructor(attrs) {
    super();
    this.tag = attrs['tag'];
    this.tagId = attrs['tagId'] || this.tag.id;
    this.isAllowedThirdPartyTag = Factory._attrOrDefault(attrs['isAllowedThirdPartyTag'], false);
    this.isThirdPartyTag = Factory._attrOrDefault(attrs['isThirdPartyTag'], true);
    this.considerQueryParamChangesNewTag = Factory._attrOrDefault(attrs['considerQueryParamChangesNewTag'], false);
    this.throttleMinuteThreshold = Factory._attrOrDefault(attrs['throttleMinuteThreshold'], 0);
    this.scheduledAuditMinuteInterval = Factory._attrOrDefault(attrs['scheduledAuditMinuteInterval'], 5);
    this.releaseCheckMinuteInterval = Factory._attrOrDefault(attrs['releaseCheckMinuteInterval'], 5);
    this.deletedAt = Factory._attrOrDefault(attrs['deletedAt'], null);
  }

  async createNewRecord() {
    const res = await DBConnecter.query(`
      INSERT INTO tag_preferences(
        tag_id,
        is_allowed_third_party_tag,
        is_third_party_tag,
        consider_query_param_changes_new_tag,
        throttle_minute_threshold,
        scheduled_audit_minute_interval,
        release_check_minute_interval,
        deleted_at
      )
      VALUES (
        ${this.tagId},
        ${this.isAllowedThirdPartyTag},
        ${this.isThirdPartyTag},
        ${this.considerQueryParamChangesNewTag},
        ${this.throttleMinuteThreshold},
        ${this.scheduledAuditMinuteInterval},
        ${this.releaseCheckMinuteInterval},
        ${this.deletedAt}
      )
    `)
    return this.id = res.insertId;
  }
}