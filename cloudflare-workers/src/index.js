import newDataProducer from './producers/new-data-producer';
import newDataConsumer from './consumers/new-data-consumer';

export default {
	async fetch(request, env, _context) {
		return await newDataProducer(request, env);
	},

	async queue(batch, _env, _context) {
		return await newDataConsumer(batch.messages)
	}
}