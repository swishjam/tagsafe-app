'use strict';

const PuppeteerModerator = require('./src/puppeteerModerator');

require('dotenv').config();

module.exports.handle = async (event, _context) => {
  console.log(`event payload:`);
  console.log(JSON.stringify(event));
  const puppeteerModerator = new PuppeteerModerator;
  const page = await puppeteerModerator.launch();

  await page.setRequestInterception(true);
  page.on('request', async req => await req.abort());
  
  await page.goto('about:blank', { waitUntil: 'domcontentloaded' });
  await page.addScriptTag({ content: 'console.log("hello world"); '}); // some tags append above first script tag.
  await page.evaluate(event.snippet);

  const tagUrlsAddedBySnippet = await page.evaluate(() => Array.from(document.querySelectorAll('script[src]')).map(script => script.getAttribute('src')))
  await puppeteerModerator.shutdown();

  return tagUrlsAddedBySnippet;
}