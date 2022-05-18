const mysql = require('mysql'),
        moment = require('moment');

module.exports = class DataStoreManager {
  _initializeMysqlIfNecessary() {
    if(!this.mysqlConnection || this.mysqlConnection.state !== 'authenticated') {
      console.log(`Connecting to MySQL DB ${process.env.MYSQL_DATABASE} at ${process.env.MYSQL_HOST}`)
      const connection = mysql.createConnection({
        host     : process.env.MYSQL_HOST,
        user     : process.env.MYSQL_USER,
        password : process.env.MYSQL_PASSWORD,
        database : process.env.MYSQL_DATABASE,
        ssl: {}
      });
      connection.connect();
      console.log(`Connected to DB!`);
      this.mysqlConnection = connection;
    }
    return this.mysqlConnection;
  }

  static formattedTs (ts) {
    return moment.utc(ts).format('YYYY-MM-DD HH:mm:ss')
  }

  async getTagUptimeConfigurationsForRegion() {
    console.log(`Fetching tags configured for uptime monitoring in ${process.env.AWS_REGION}....`);
    const queryResults = await this._queryDB(`
      SELECT 
        tags.id AS tag_id,
        tags.full_url AS tag_url,
        uptime_regions.id AS uptime_region_id
      FROM 
        tags
        INNER JOIN domains
          ON domains.id=tags.domain_id
        INNER JOIN subscription_plans
          ON subscription_plans.id=domains.current_subscription_plan_id
        LEFT JOIN credit_wallets AS credit_wallet_for_current_month
          ON credit_wallet_for_current_month.domain_id=domains.id AND
          credit_wallet_for_current_month.month=${parseInt(moment(new Date()).format('M'))}
        INNER JOIN uptime_regions_to_check 
          ON uptime_regions_to_check.tag_id=tags.id
        INNER JOIN uptime_regions 
          ON uptime_regions.id=uptime_regions_to_check.uptime_region_id
      WHERE 
        uptime_regions.aws_name = "${process.env.AWS_REGION}" AND
        subscription_plans.status NOT IN ("incomplete_expired", "unpaid", "canceled") AND
        (
          credit_wallet_for_current_month.credits_remaining IS NULL OR 
          credit_wallet_for_current_month.credits_remaining > 0
        )
      GROUP BY
        tag_id,
        tag_url,
        uptime_region_id
    `)
    await this.killConnection();
    return queryResults;
  }

  async createUptimeBatch({ batchUid, numTagsChecked, executedAt, msToRunCheck }) {
    console.log(`Creating UptimeCheckBatch UID: ${batchUid}...`);
    const uptimeRegionId = await this._getUptimeRegionIdForCurrentRegion();
    const res = await this._queryDB(`
      INSERT INTO 
        uptime_check_batches(
          batch_uid,
          uptime_region_id,
          num_tags_checked,
          executed_at,
          ms_to_run_check
        )
      VALUES
        (
          "${batchUid}", 
          ${uptimeRegionId}, 
          ${numTagsChecked}, 
          "${executedAt}", 
          ${msToRunCheck}
        )
    `);
    return res.insertId;
  }

  async insertUptimeResults(formattedResults) {
    console.log(`Inserting ${formattedResults.length} records into uptime_checks table...`);
    return await this._insertRowsIntoDB(`
      INSERT INTO 
        uptime_checks (
          tag_id, 
          uptime_check_batch_id, 
          uptime_region_id, 
          response_time_ms, 
          response_code,
          created_at,
          executed_at
        ) 
      VALUES ?`, formattedResults);
  }

  async killConnection() {
    return new Promise(resolve => {
      this.mysqlConnection.end(function(err) {
        if(err) console.error(`Closing MySQL connection threw an error, cannot close: ${err}`);
        console.log('Closed MySQL connection!');
        resolve();
      });
    })
  }

  async _getUptimeRegionIdForCurrentRegion() {
    const results = await this._queryDB(`SELECT id FROM uptime_regions WHERE uptime_regions.aws_name = "${process.env.AWS_REGION}"`)
    return results[0].id;
  }

  async _queryDB(sqlQuery) {
    return new Promise(resolve => {
      this._initializeMysqlIfNecessary();
      this.mysqlConnection.query(sqlQuery, (error, results, _fields) => {
        if(error) {
          console.log(`MySQL Query failed!`)
          console.log(`Attempted query: ${sqlQuery}`);
          throw new Error(error)
        } else {
          resolve(results);
        }
      })
    })
  };

  async _insertRowsIntoDB(sql, rows) {
    return new Promise(resolve => {
      this._initializeMysqlIfNecessary();
      this.mysqlConnection.query(sql, [rows], (error, results, _fields) => {
        if(error) {
          console.log(`MySQL Query failed!`)
          console.log(`Attempted query: ${sql}`);
          throw new Error(error)
        } else {
          resolve(results);
        }
      })
    })
  }
}