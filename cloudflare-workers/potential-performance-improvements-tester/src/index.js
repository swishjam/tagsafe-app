export default {
	async fetch(request, _env, _context) {
		const originalHost = request.headers.get('x-host');
		if (originalHost) {
			const url = new URL(request.url);
			const originUrl = url.protocol + '//' + originalHost + url.pathname + url.search;
			const init = {
				method: request.method,
				// redirect: "manual",
				headers: [...request.headers]
			};
			console.log(`Fetching content from ${originUrl}...`);
			return await fetch(originUrl, init);
		} else {
			return new Response('x-Host headers missing', { status: 403 });
		}
	},
};
