import newDataProducer from './producers/new-data-producer';
import newDataConsumer from './consumers/new-data-consumer';
import { Toucan } from 'toucan-js';


export default {
	async fetch(request, env, context) {
		const Sentry = new Toucan({ dsn: env.SENTRY_DSN, context, request, environment: env.ENVIRONMENT });
		try {
			return await newDataProducer(request, env);
		} catch(err) {
			Sentry.captureException(err);
			throw err;
		}
	},

	async queue(batch, env, context) {
		const Sentry = new Toucan({ dsn: env.SENTRY_DSN, context, request: batch, environment: env.ENVIRONMENT });
		try {
			return await newDataConsumer(batch.messages, env);
		} catch(err) {
			Sentry.captureException(err);
			throw err
		}
	}
}