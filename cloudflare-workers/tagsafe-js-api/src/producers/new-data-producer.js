export default async function newDataProducer(request, env) {
  try {
    const payload = await request.json();

    console.log(payload);
    await env.DATA_CONSUMER_QUEUE.send({ ts: Date.now(), ...payload })
    console.log(`Pushed data to Cloudflare Queue: ${JSON.stringify(payload)}`);

    const status = 200;
    const headers = { 'Access-Control-Allow-Origin': '*', 'Content-type': 'application/json' };
    return new Response(null, { status, headers });
  } catch(err) {
    console.error(`Cannot push data to Cloudflare Queue, err: ${err.message}`);
    console.error(`Request body: ${await request.text()}`);
    const status = 200;
    // const headers = { 'Access-Control-Allow-Origin': '*' };
    const headers = {};
    return new Response(null, { status, headers });
  }
};