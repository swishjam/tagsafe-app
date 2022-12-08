import newTagsProducer from './producers/new-tags-producer';
import newTagsConsumer from './consumers/new-tags-consumer';

export default {
	async fetch(request, env, _context) {
		return await newTagsProducer(request, env);
	},

	async queue(batch, _env, _context) {
		return await newTagsConsumer(batch.messages)
	}
}