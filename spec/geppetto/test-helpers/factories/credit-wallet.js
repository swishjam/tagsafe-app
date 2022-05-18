const moment = require('moment'),
        Factory = require('./factory'),
        DBConnecter = require('../dbConnecter');

module.exports = class CreditWallet extends Factory {
  constructor(attrs) {
    super();
    this.domain = attrs['domain'];
    this.domainId = attrs['domainId'] || this.domain.id;
    this.month = Factory._attrOrDefault(attrs['month'], moment.utc(new Date()).format('M'));
    this.totalCreditsForMonth = Factory._attrOrDefault(attrs['totalCreditsForMonth'], 1_000);
    this.creditsUsed = Factory._attrOrDefault(attrs['creditsUsed'], 500);
    this.creditsRemaining = Factory._attrOrDefault(attrs['creditsRemaining'], 500);
    this.disabledAt = Factory._attrOrDefault(attrs['disabledAt'] || null);
  }

  async createNewRecord() {
    const res = await DBConnecter.query(`
      INSERT INTO credit_wallets(
        domain_id,
        month,
        total_credits_for_month,
        credits_used,
        credits_remaining,
        disabled_at,
        created_at,
        updated_at
      )
      VALUES (
        ${this.domainId},
        ${this.month},
        ${this.totalCreditsForMonth},
        ${this.creditsUsed},
        ${this.creditsRemaining},
        ${this.disabledAt},
        "${Factory.now()}",
        "${Factory.now()}"
      )
    `);
    return this.id = res.insertId;
  }
}