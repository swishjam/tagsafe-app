const mysql = require('mysql'),
        moment = require('moment');

module.exports = class DBConnection {
  static get connection() {
    if(!this._connection || this._connection.state !== 'authenticated') {
      process.env.MYSQL_HOST = 'localhost';
      process.env.MYSQL_USER = 'root';
      process.env.MYSQL_PASSWORD = 'password';
      process.env.MYSQL_DATABASE = 'tagsafe_test';

      this._connection = mysql.createConnection({
        host     : process.env.MYSQL_HOST,
        user     : process.env.MYSQL_USER,
        password : process.env.MYSQL_PASSWORD,
        database : process.env.MYSQL_DATABASE
      });
      this._connection.connect();
    }
    return this._connection;
  }

  static setUpTests = () => {
    beforeEach(async () => {
      await this.truncateTables();
    })
    
    afterEach(async () => {
      await this.truncateTables();
      await this.disconnect();
    })
  }

  static truncateTables = async () => {
    await this.query('SET FOREIGN_KEY_CHECKS=0;');
    const tables = await this.query(`SELECT TABLE_NAME FROM information_schema.tables WHERE table_schema="${process.env.MYSQL_DATABASE}"`);
    for(let i = 0; i < tables.length; i++) {
      const table = tables[i];
      await this.query(`TRUNCATE TABLE ${table.TABLE_NAME}`);
    }
    await this.query('SET FOREIGN_KEY_CHECKS=1;');
    console.log(`Truncated ${tables.length} tables from ${process.env.MYSQL_DATABASE}`);
  }
  
  static disconnect = async () => {
    return new Promise(resolve => {
      this.connection.end(function(err) {
        if(err) console.error(`Closing MySQL connection threw an error, cannot close: ${err}`);
        console.log('Closed MySQL connection');
        resolve();
      });
    })
  }

  static query = async sql => {
    return new Promise(resolve => {
      this.connection.query(sql, (error, results, _fields) => {
        if(error) {
          console.error(`MySQL Query failed!`)
          console.error(`Attempted query: ${sql}`);
          throw new Error(error)
        } else {
          resolve(results);
        }
      })
    })
  }
  
  static insertRowsIntoDB = async (sql, rows) => {
    return new Promise(resolve => {
      this.connection.query(sql, [rows], (error, results, _fields) => {
        if(error) {
          console.error(`MySQL Query failed!`)
          console.error(`Attempted query: ${sql}`);
          throw new Error(error)
        } else {
          resolve(results);
        }
      })
    })
  }

  static date = _date => {
    return moment.utc(_date).format('YYYY-MM-DD HH:mm:ss');
  }

  static now = () => {
    return this.date(Date.now());
  }
}