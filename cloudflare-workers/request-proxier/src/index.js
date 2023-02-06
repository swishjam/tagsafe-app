export default {
	async fetch(request, _env, _context) {
		const originUrl = new URL(request.url).searchParams.get('url');
		if (originUrl === null) {
			return new Response('Missing required param: \`url`', { status: 400 });
		} else {
			console.log(`Fetching origin content from: ${originUrl}`);
			const originRequest = new Request(originUrl, request);
			const proxyResponse = await fetch(originRequest);
			console.log(`Returning proxied response: ${proxyResponse.status}`);
			return proxyResponse;
		}
	},
};
