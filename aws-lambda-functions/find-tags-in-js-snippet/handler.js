const PuppeteerModerator = require("./src/puppeteerModerator");

module.exports.handle = async (event, _context) => {
  const { tag_snippet_script, script_tags_attributes = [] } = event;

  console.log(`Running script: ${tag_snippet_script}`);
  console.log(`Script tag attributes: ${script_tags_attributes.join(', ')}`)
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



  await page.evaluate((encodedScriptTagJsContent, scriptTagAttrs) => {
    var s = document.createElement('script');
    scriptTagAttrs.forEach(attr => s.setAttribute(attr[0], attr[1]));

    const scriptSrc = s.getAttribute('src');
    if(scriptSrc && !scriptSrc.startsWith('http')) {
      if(scriptSrc.startsWith('//')) {
        s.setAttribute('src', `https:${scriptSrc}`)
      } else {
        s.setAttribute('src', `https://${scriptSrc}`);
      }
    }
    s.innerText = window.atob(encodedScriptTagJsContent);
    document.head.appendChild(s);
  }, tag_snippet_script, script_tags_attributes);

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
