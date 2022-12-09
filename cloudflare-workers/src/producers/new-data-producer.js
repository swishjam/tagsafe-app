export default async function newDataProducer(request, env) {
  const payload = await request.json();

  console.log(payload)
  await env.DATA_CONSUMER_QUEUE.send(payload)
  console.log(`Pushed data to Cloudflare Queue: ${JSON.stringify(payload)}`);

  const status = 200;
  const headers = { 'Access-Control-Allow-Origin': '*', 'Content-type': 'application/json' };
  return new Response(null, { status, headers });
};