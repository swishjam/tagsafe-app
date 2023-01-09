const PuppeteerModerator = require("./src/puppeteerModerator");
const fs = require('fs');

module.exports.handle = async (event, _context) => {
  const { tag_snippet_script } = event;

  console.log(`Running script: ${tag_snippet_script}`);
  const puppeteerModerator = new PuppeteerModerator()
  const page = await puppeteerModerator.launch();
  await page.goto('about:blank', { waituntil: 'load' });
  await page.addScriptTag({ content: 'console.log("hello world"); ' }); // some tags append above first script tag.
  await page.evaluate(tag_snippet_script);

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
