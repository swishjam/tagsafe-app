const { createClient } = require('redis');

class ResqueEnqueuer {
  constructor({ tagsafeConsumerResqueKlass, tagsafeConsumerResqueQueue }) {
    this.tagsafeRedisUrl = process.env.TAGSAFE_REDIS_URL;
    this.tagsafeConsumerResqueQueue = tagsafeConsumerResqueQueue;
    this.tagsafeConsumerResqueKlass = tagsafeConsumerResqueKlass;
    this.sentSuccessfully = false;
    this.redisConnectTimeoutMs = parseInt(process.env.REDIS_CONNECT_TIMEOUT_MS || 4_000);
  }

  initializeRedis = () => {
    if(this.redis) throw new Error(`Redis already initialized!`);
    console.log(`Connecting to Redis client at ${this.tagsafeRedisUrl}`);
    this.redis = createClient({ url: this.tagsafeRedisUrl });
    this.redis.on('error', err => console.error(`Redis client encountered an error: ${err}`) );
    this.redis.on('connect', () => console.log('Initiating Redis connection...') )
    this.redis.on('ready', async () => console.log(`Redis successfully connected`) );
    this.redis.on('end', () => console.log('Redis disconnected') );
    this.redis.on('reconnecting', () => console.log('Attempting to re-connect to Redis...') );
  }

  _connectToRedisOrThrowError = async () => {
    setTimeout(() => {
      if(!this.connectedToRedis) {
        throw new Error(`Unable to connect to Redis (${this.tagsafeRedisUrl}) within ${this.redisConnectTimeoutMs / 1_000} seconds.`);
      }
    }, this.redisConnectTimeoutMs);
    const start = Date.now();
    this.initializeRedis();
    await this.redis.connect();
    this.connectedToRedis = true;
    console.log(`Connected to Redis in ${Date.now() - start} ms.`);
  }

  enqueueData = async data => {
    try {
      await this._connectToRedisOrThrowError();
  
      const tagsafeFormattedResqueJob = {
        "class": "ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper",
        "args": [
          {
            "job_class": this.tagsafeConsumerResqueKlass,
            "job_id": this._generateResqueJobId(),
            "provider_job_id": null,
            "queue_name": this.tagsafeConsumerResqueQueue,
            "priority": null,
            "arguments": [data],
            "executions":0,
            "exception_executions":{},
            "locale":"en",
            "timezone":"Pacific Time (US \u0026 Canada)",
            "enqueued_at":`${new Date()}`
          }
        ]
      };
      await this.redis.rPush(`resque:queue:${this.tagsafeConsumerResqueQueue}`, JSON.stringify(tagsafeFormattedResqueJob));
      this.sentSuccessfully = true;
      await this.killRedisConnection();
      console.log(`Sent data into Resque ${this.tagsafeConsumerResqueQueue} queue.`);
      return tagsafeFormattedResqueJob;
    } catch(err) {
      console.error(`Encountered error in enqueueIntoTagsafeResque: ${err}`);
      await this.killRedisConnection();
      throw new Error(err);
    }
  }

  killRedisConnection = async () => {
    if(this.redis && this.redis.isOpen) await this.redis.quit();
  }
  
  _generateResqueJobId = () => {
    return [
      [
        'aws0',
        [...Array(4)].map(() => Math.floor(Math.random() * 16).toString(16)).join('')
      ].join(''),
      [...Array(4)].map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
      [...Array(4)].map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
      [...Array(12)].map(() => Math.floor(Math.random() * 16).toString(16)).join('')
    ].join('-');
  }
}

module.exports = ResqueEnqueuer;