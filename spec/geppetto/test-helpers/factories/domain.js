const Factory = require('./factory'),
      DBConnecter = require('../dbConnecter');

module.exports = class Domain extends Factory {
  constructor(attrs) {
    super();
    this.url = Factory._attrOrDefault(attrs['url'], 'https://www.test.com');
    this.stripeCustomerId = Factory._attrOrDefault(attrs['stripeCustomerId'], 'cus_abc123');
    this.stripePaymentMethodId = Factory._attrOrDefault(attrs['stripePaymentMethodId'], 'pm_xyz_789');
    this.currentSubscriptionPlan = Factory._attrOrDefault(attrs['currentSubscriptionPlan'], null);
  }

  async update(updateAttrs = {}) {
    this.url = updateAttrs['url'] || this.url;
    this.stripeCustomerId = updateAttrs['stripeCustomerId'] || this.stripeCustomerId;
    this.stripePaymentMethodId = updateAttrs['stripePaymentMethodId'] || this.stripePaymentMethodId;
    this.currentSubscriptionPlan = updateAttrs['currentSubscriptionPlan'] || this.currentSubscriptionPlan;
    return await this._updateRecord();
  }

  async createNewRecord() {
    const result = await DBConnecter.query(`
      INSERT INTO 
        domains(url, stripe_customer_id, stripe_payment_method_id, created_at, updated_at)
      VALUES 
        ("${this.url}", "${this.stripeCustomerId}", "${this.stripePaymentMethodId}", "${Factory.now()}", "${Factory.now()}")
    `);
    return this.id = result.insertId;
  }

  async _updateRecord() {
    if(!this.id) throw Error(`Must call create before you can update the record.`);
    return await DBConnecter.query(`
      UPDATE domains
      SET
        url = "${this.url}",
        stripe_customer_id = "${this.stripeCustomerId}",
        stripe_payment_method_id = "${this.stripePaymentMethodId}",
        current_subscription_plan_id = "${this.currentSubscriptionPlan?.id}",
        updated_at = "${Factory.now()}"
      WHERE id = ${this.id}
    `)
  }
}