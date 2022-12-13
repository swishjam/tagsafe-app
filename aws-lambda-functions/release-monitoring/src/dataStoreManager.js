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

  static formattedTs(ts) {
    return moment.utc(ts).format('YYYY-MM-DD HH:mm:ss');
  }

  async getReleaseCheckConfigurationsForInterval(interval) {
    console.log(`Fetching release check config for tags on ${interval} interval...`);
    const queryResults = await this._queryDB(`
      SELECT 
        tags.id AS tag_id,
        tags.full_url AS tag_url, 
        tags.release_monitoring_interval_in_minutes AS release_monitoring_interval_in_minutes, 
        most_recent_tag_versions.hashed_content AS current_hashed_content,
        most_recent_tag_versions.bytes AS current_version_bytes_size,
        tags.marked_as_pending_tag_version_capture_at AS marked_as_pending_tag_version_capture_at
      FROM 
        tags
        INNER JOIN tag_versions AS most_recent_tag_versions 
          ON most_recent_tag_versions.id=tags.most_recent_tag_version_id
      WHERE 
        tags.release_monitoring_interval_in_minutes = ${parseInt(interval)}
      GROUP BY
        tags.id, 
        release_monitoring_interval_in_minutes, 
        current_hashed_content,
        current_version_bytes_size,
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