const Factory = require('./factory'),
      DBConnecter = require('../dbConnecter');

module.exports = class SubscriptionPlan extends Factory {
  constructor(attrs) {
    super();
    this.domain = attrs['domain'];
    this.domainId = attrs['domainId'] || this.domain.id;
    this.amount = Factory._attrOrDefault(attrs['amount'], 1000_00);
    this.status = Factory._attrOrDefault(attrs['status'], 'active');
    this.packageType = Factory._attrOrDefault(attrs['packageType'], 'pro');
    this.billingInterval = Factory._attrOrDefault(attrs['billingInterval'], 'month');
  }

  async createNewRecord() {
    const res = await DBConnecter.query(`
      INSERT INTO subscription_plans(
        domain_id,
        stripe_subscription_id,
        status,
        package_type,
        billing_interval,
        amount,
        created_at,
        updated_at
      )
      VALUES (
        ${this.domainId},
        'sub_abc123',
        '${this.status}',
        '${this.packageType}',
        '${this.billingInterval}',
        ${this.amount},
        "${Factory.now()}",
        "${Factory.now()}"
      )
    `);
    return this.id = res.insertId;
  }
}