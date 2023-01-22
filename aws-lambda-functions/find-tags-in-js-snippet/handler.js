const PuppeteerModerator = require("./src/puppeteerModerator");

module.exports.handle = async (event, _context) => {
  const { encoded_tag_snippet_content } = event;

  console.log(`Running script: ${encoded_tag_snippet_content}`);

  const puppeteerModerator = new PuppeteerModerator()
  const page = await puppeteerModerator.launch();

  await page.setRequestInterception(true);
  page.on('request', async req => {
    if(['POST', 'UPDATE', 'PATCH'].includes(req.method())) {
      await req.abort();
    } else {
      await req.continue();
    }
  })

  await page.goto('about:blank', { waituntil: 'load' });
  await page.addScriptTag({ content: 'console.log("hello world");' }); // some tags append above first script tag.

  await page.evaluate(encodedScriptTagContent => {
    const htmlString = window.atob(encodedScriptTagContent);
    const htmlFragment = document.createRange().createContextualFragment(htmlString);
    document.head.appendChild(htmlFragment);    
  }, encoded_tag_snippet_content);

  await new Promise(r => setTimeout(r, 5_000));

  const tagsAddedBySnippet = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('script[src]')).map(scriptEl => {
      return {
        url: scriptEl.getAttribute('src'),
        load_type: scriptEl.getAttribute('defer') ? 'defer' : scriptEl.getAttribute('async') ? 'async' : 'synchronous',
        fetch_priority_attr: scriptEl.getAttribute('fetchpriority'),
        integrity_attr: scriptEl.getAttribute('integrity'),
        nonce_attr: scriptEl.getAttribute('nonce'),
        referrer_policy_attr: scriptEl.getAttribute('referrerpolicy'),
        type_attr: scriptEl.getAttribute('type'),
        blocking_attr: scriptEl.getAttribute('blocking'),
      }
    })
  })
  
  await puppeteerModerator.shutdown();
  console.log(tagsAddedBySnippet);
  return tagsAddedBySnippet;
}
