const Factory = require('./factory'),
        DBConnecter = require('../dbConnecter');

module.exports = class UptimeRegion extends Factory {
  constructor(attrs) {
    super();
    this.uptimeRegion = attrs['uptimeRegion'];
    this.tag = attrs['tag'];
  }

  async createNewRecord() {
    const res = await DBConnecter.query(`
      INSERT INTO uptime_regions_to_check(uptime_region_id, tag_id)
      VALUES (${this.uptimeRegion.id}, ${this.tag.id})
    `);
    return this.id = res.insertId;
  }
}