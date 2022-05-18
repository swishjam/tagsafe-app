const Factory = require('./factory'),
      DBConnecter = require('../dbConnecter');

module.exports = class Tag extends Factory {
  constructor(attrs) {
    super();
    this.domain = attrs['domain'];
    this.domainId = attrs['domainId'] || this.domain.id;
    this.fullUrl = Factory._attrOrDefault(attrs['fullUrl'], 'https://www.tag.com/script.js');
    this.urlDomain = new URL(this.fullUrl).hostname;
    this.urlPath = new URL(this.fullUrl).pathname;
    this.urlQueryParam = new URL(this.fullUrl).query;
    this.markedAsPendingTagVersionCaptureAt = attrs['markedAsPendingTagVersionCaptureAt'];
  }

  async createNewRecord() {
    const res = await DBConnecter.query(`
      INSERT INTO tags(
        domain_id,
        url_domain,
        url_path,
        url_query_param,
        full_url,
        marked_as_pending_tag_version_capture_at,
        removed_from_site_at,
        created_at,
        deleted_at
      )
      VALUES (
        ${this.domainId},
        "${this.urlDomain}",
        "${this.urlPath}",
        "${this.urlQueryParam}",
        "${this.fullUrl}",
        null,
        null,
        "${Factory.now()}",
        null
      )
    `)
    return this.id = res.insertId;
  }
}