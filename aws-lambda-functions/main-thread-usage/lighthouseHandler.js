const chromium = require('chrome-aws-lambda');
const lighthouse = require('lighthouse');
const fs = require('fs');

module.exports.handle = async (event, context) => {
  const {
    page_url,
    tag_url,
    request_url_to_overwrite,
    request_url_to_overwrite_to,
    main_thread_blocking_multiplier = 0.2,
    total_main_thread_execution_multiplier = 0.1,
    navigation_wait_until = 'networkidle0'
  } = event;

  if (!page_url || !tag_url || !request_url_to_overwrite || !request_url_to_overwrite_to) {
    throw new Error('\
      Invalid invocation, missing required args. \
      MainThreadExecutionEvaluator must be called with `page_url`, `tag_url`, `request_url_to_overwrite`, and `request_url_to_overwrite_to`. \
    ')
  }

  console.log('Launching browser...');
  const browser = await chromium.puppeteer.launch();
  console.log('Setting up request overrides...');
  await setupRequestOverrides(browser, { request_url_to_overwrite: request_url_to_overwrite_to });

  console.log('Running lighthouse audit....');
  const {lhr} = await lighthouse(page_url, {
    port: (new URL(browser.wsEndpoint())).port,
    output: 'json',
    logLevel: 'info'
  });

  console.log(lhr);
  await browser.close();
  fs.writeFileSync('./lighthouse.json', JSON.stringify(lhr));
  return lhr;
}

const setupRequestOverrides = async (browser, urlOverrideMap) => {
  // browser.on('targetchanged', async target => {
  //   const page = await target.page();
  //   await page.setRequestInterception(true);
  //   page.on('request', async req => {
  //     const parsedRequestUrl = new URL(req.url());
  //     const urlToOverrideTo = urlOverrideMap[parsedRequestUrl.href] || 
  //                               urlOverrideMap[`${parsedRequestUrl.ostname}${parsedRequestUrl.pathname}`] ||
  //                               urlOverrideMap[`${parsedRequestUrl.protocol}//${parsedRequestUrl.hostname}${parsedRequestUrl.pathname}`];
  //     if (urlToOverrideTo) {
  //       console.log(`Intercepting ${req.url()} and overriding it to ${urlToOverrideTo}!`);
  //       await req.continue({ url: urlToOverrideTo });
  //     } else {
  //       req.continue();
  //     }
  //   })
  // })
}