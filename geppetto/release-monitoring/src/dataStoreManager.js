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
        ssl: 'Amazon RDS'
      });
      connection.connect();
      console.log(`Connected to DB!`);
      this.mysqlConnection = connection;
    }
    return this.mysqlConnection;
  }

  static formattedTs(ts) {
    return moment.utc(ts).format('YYYY-MM-DD HH:mm:ss');
  }

  async getReleaseCheckConfigurationsForInterval(interval) {
    console.log(`Fetching release check config for tags on ${interval} interval...`);
    const queryResults = await this._queryDB(`
      SELECT 
        tags.id AS tag_id,
        tags.full_url AS tag_url, 
        tag_preferences.release_check_minute_interval AS release_check_minute_interval, 
        current_tag_versions.hashed_content AS current_hashed_content,
        current_tag_versions.bytes AS current_version_bytes_size,
        tags.marked_as_pending_tag_version_capture_at AS marked_as_pending_tag_version_capture_at,
        CASE
          WHEN tag_general_configurations.num_recent_tag_versions_to_compare_in_release_monitoring IS NULL
          THEN domain_general_configurations.num_recent_tag_versions_to_compare_in_release_monitoring
          ELSE tag_general_configurations.num_recent_tag_versions_to_compare_in_release_monitoring
        END AS num_recent_tag_versions_to_compare_in_release_monitoring
      FROM 
        tags
        INNER JOIN domains
          ON domains.id=tags.domain_id
        INNER JOIN subscription_plans
          ON subscription_plans.id=domains.current_subscription_plan_id
        LEFT JOIN credit_wallets AS credit_wallet_for_current_month_and_year
          ON credit_wallet_for_current_month_and_year.domain_id=domains.id AND
          credit_wallet_for_current_month_and_year.month=${parseInt(moment(new Date()).format('M'))} AND
          credit_wallet_for_current_month_and_year.year=${parseInt(moment(new Date()).format('Y'))}
        INNER JOIN tag_preferences 
          ON tag_preferences.tag_id=tags.id
        LEFT JOIN general_configurations 
          AS domain_general_configurations 
          ON domain_general_configurations.parent_type = "Domain" 
          AND domain_general_configurations.parent_id=tags.domain_id
        LEFT JOIN general_configurations 
          AS tag_general_configurations 
          ON tag_general_configurations.parent_type = "Tag" 
          AND tag_general_configurations.parent_id=tags.id
        LEFT JOIN tag_versions 
          AS current_tag_versions 
          ON current_tag_versions.tag_id=tags.id 
          AND current_tag_versions.most_recent = true
      WHERE 
        tag_preferences.release_check_minute_interval = ${parseInt(interval)} AND
        subscription_plans.status NOT IN ("incomplete_expired", "unpaid", "canceled") AND
        (
          credit_wallet_for_current_month_and_year.credits_remaining IS NULL OR 
          credit_wallet_for_current_month_and_year.credits_remaining > 0
        )
      GROUP BY
        tag_id,
        tag_url, 
        release_check_minute_interval, 
        current_hashed_content,
        current_version_bytes_size,
        num_recent_tag_versions_to_compare_in_release_monitoring,
        marked_as_pending_tag_version_capture_at
    `)
    await this.killConnection();
    return queryResults;
  }

  async getRecentHashedContentForTag(tagId, numRecords) {
    const queryResults = await this._queryDB(`
      SELECT hashed_content
      FROM tag_versions
      WHERE
        tag_versions.tag_id = ${tagId}
      ORDER BY created_at DESC
      LIMIT ${numRecords}
    `);
    await this.killConnection();
    return queryResults.map(result => result.hashed_content);
  }

  async createReleaseCheckBatch({ batchUid, minuteInterval, numTagsWithNewVersions, numTagsWithoutNewVersions, executedAtDate }) {
    console.log(`Creating ReleaseCheckBatch UID: ${batchUid}...`);
    const res = await this._queryDB(`
      INSERT INTO 
        release_check_batches(
          batch_uid,
          minute_interval,
          num_tags_with_new_versions,
          num_tags_without_new_versions, 
          executed_at, 
          ms_to_run_check
        )
      VALUES
        (
          "${batchUid}",
          ${minuteInterval},
          ${numTagsWithNewVersions}, 
          ${numTagsWithoutNewVersions}, 
          "${DataStoreManager.formattedTs(executedAtDate)}", 
          ${new Date() - executedAtDate}
        )
    `);
    return res.insertId;
  }

  async insertReleaseCheckResults(formattedResults) {
    console.log(`Inserting ${formattedResults.length} ReleaseChecks into DB....`);
    return await this._insertRowsIntoDB(`
      INSERT INTO 
        release_checks (
          tag_id,
          release_check_batch_id,
          content_is_the_same_as_a_previous_version,
          bytesize_changed,
          hash_changed,
          captured_new_tag_version,
          created_at,
          updated_at,
          executed_at
        )
      VALUES ?`, formattedResults);
  }

  async markTagAsPendingTagVersionCapture(tagId) {
    console.log(`Setting Tag ${tagId}'s \`marked_as_pending_tag_version_capture_at\`...`);
    const queryResults = await this._queryDB(`
      UPDATE tags
      SET marked_as_pending_tag_version_capture_at = UTC_TIMESTAMP()
      WHERE tags.id = ${tagId}
    `)
    await this.killConnection();
    return queryResults;
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