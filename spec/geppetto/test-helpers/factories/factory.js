const moment = require('moment');

module.exports = class Factory {
  static async create(attrs) {
    const self = new this(attrs);
    await self.createNewRecord();
    return self;
  }

  static date(_date) {
    return moment.utc(_date).format('YYYY-MM-DD HH:mm:ss')
  }

  static now() {
    return this.date(new Date());
  }

  static _attrOrDefault(attr, defaultVal) {
    return typeof attr === 'undefined' ? defaultVal : attr;
  }
}