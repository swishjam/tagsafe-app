const PuppeteerModerator = require('./src/puppeteerModerator');
const fs = require('fs');

require('dotenv').config();

module.exports.handle = async (event, _context) => {
  const urlsToCheck = [
    'https://www.shopify.com/',
    'https://www.homedepot.com',
    'https://www.walmart.com/',
    'https://www.amazon.com/',
    'https://www.target.com/',
    'https://www.bestbuy.com/',
    'https://www.ebay.com/',
    'https://www.lowes.com/',
    'https://www.macys.com/',
    'https://www.nordstrom.com/',
    'https://www.sephora.com/',
    'https://www.ulta.com/',
    'https://www.walgreens.com/',
    'https://www.costco.com/',
    'https://www.barnesandnoble.com/',
    'https://www.etsy.com/',
    'https://www.overstock.com/',
    'https://www.wayfair.com/',
    'https://www.zappos.com/',
    'https://www.saksfifthavenue.com/',
    'https://www.asos.com/',
    'https://www.bloomingdales.com/',
    'https://www.dickssportinggoods.com/',
    'https://www.kohls.com/',
    'https://www.ikea.com/',
    'https://www.footlocker.com/',
    'https://www.athleta.com/',
    'https://www.burtsbees.com/',
    'https://www.crateandbarrel.com/',
    'https://www.dsw.com/',
    'https://www.gap.com/',
    'https://www.hollisterco.com/',
    'https://www.jcrew.com/',
    'https://www.landsend.com/',
    'https://www.lululemon.com/',
    'https://www.michaels.com/',
    'https://www.newegg.com/',
    'https://www.nike.com/',
    'https://www.potterybarn.com/',
    'https://www.rei.com/',
    'https://www.saks.com/',
    'https://www.saksfifthavenue.com/',
    'https://www.llbean.com/',
    'https://www.tjmaxx.com/',
    'https://www.toysrus.com/',
    'https://www.urbanoutfitters.com/',
    'https://www.victoriassecret.com/',
    'https://www.westelm.com/',
    'https://www.zara.com/',
    'https://www.zulily.com/',
    'https://www.bathandbodyworks.com/',
    'https://www.williams-sonoma.com/',
    'https://www.underarmour.com/',
    'https://www.ulta.com/',
    'https://www.toryburch.com/',
    'https://www.adidas.com/',
    'https://www.ralphlauren.com/',
    'https://www.reebok.com/',
    'https://www.footaction.com/',
    'https://www.toms.com/',
    'https://www.ugg.com/',
    'https://www.zappos.com/',
    'https://www.oldnavy.com/',
    'https://www.qvc.com/',
    'https://www.tillys.com/',
    'https://www.carters.com/',
    'https://www.zumiez.com/',
    'https://www.groupon.com/',
    'https://www.stripe.com/',
    'https://www.jcpenney.com/',
    'https://www.pacsun.com/',
    'https://www.vans.com/',
    'https://www.tiffany.com/',
    'https://www.converse.com/',
    'https://www.rue21.com/',
    'https://www.xfinity.com/',
    'https://www.delta.com/',
    'https://www.kmart.com/',
    'https://www.dominos.com/',
    'https://www.ae.com/',
    'https://www.express.com/',
    'https://www.pier1.com/',
    'https://www.lacoste.com/',
    'https://www.levi.com/',
    'https://www.officedepot.com/',
    'https://www.acehardware.com/',
    'https://www.eastbay.com/',
    'https://www.newbalance.com/',
    'https://www.puma.com/',
    'https://www.famousfootwear.com/',
    'https://www.chipotle.com/',
    'https://www.avis.com/',
    'https://www.nytimes.com/',
    'https://www.hilton.com/',
    'https://www.lordandtaylor.com/',
    'https://www.doordash.com/',
    'https://www.sears.com/',
    'https://www.yelp.com/',
    'https://www.tacobell.com/',
    'https://www.cvs.com/',
  ]

  const puppeteerModerator = new PuppeteerModerator();
  const page = await puppeteerModerator.launch();

  let results = {};
  let totalNumUniqueHosts = 0;
  let totalUrlsChecked = 0;
  for(let url of urlsToCheck) {
    try {
      console.log(`Getting results for ${url}.....`);
      await page.goto(url, { waituntil: ['domcontentloaded', 'networkidle2'] });
      await new Promise(resolve => setTimeout(resolve, 5_000));
      const uniqueHosts = await page.evaluate(() => {
        let uniqueHosts = {};
        window.performance.getEntriesByType('resource').forEach(resource => {
          const host = new URL(resource.name).host;
          if (!uniqueHosts[host]) uniqueHosts[host] = true;
        });
        return uniqueHosts;
      });
      const numUniqueHosts = Object.keys(uniqueHosts).length;
      console.log(`Found ${numUniqueHosts} unique hosts for ${url}!`);
      totalNumUniqueHosts += numUniqueHosts;
      totalUrlsChecked += 1;
      results[url] = { count: numUniqueHosts, hosts: Object.keys(uniqueHosts) };
    } catch(err) {
      console.log(`Could not get results for ${url}: ${err}`);
    }
  }

  const average = totalNumUniqueHosts / totalUrlsChecked;
  fs.writeFileSync(`results.json`, JSON.stringify({ average, ...results}, null, 2));
  return results;
}