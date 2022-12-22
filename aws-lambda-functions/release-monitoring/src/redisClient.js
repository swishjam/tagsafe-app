const { createClient } = require('redis');

class RedisClient {
  constructor(redisUrl) {
    this.redisUrl = redisUrl;
  }

  async client() {
    return this._client = this._client || await this._init();
  }

  async _init() {
    let connectedToRedis = false;
    console.log(`Connecting to Redis client at ${this.redisUrl}`);
    const client = createClient({ url: this.redisUrl });
    client.on('error', err => { throw err });
    client.on('connect', () => console.log('Initiating Redis connection...') )
    client.on('ready', () => console.log(`Redis successfully connected!`) );
    client.on('end', () => console.log('Redis disconnected') );
    client.on('reconnecting', () => console.log('Attempting to re-connect to Redis...') );
    setTimeout(() => {
      if(!connectedToRedis) {
        throw new Error(`Unable to connect to Redis within 5 seconds (Redis URL: ${this.redisUrl})`);
      }
    }, 5_000);
    await client.connect();
    connectedToRedis = true;
    return client;
  }
}

module.exports = RedisClient;