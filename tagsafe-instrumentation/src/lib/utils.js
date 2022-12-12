export function urlToDomain(url) {
  const splitHost = new URL(url).hostname.split('.');
  if(splitHost.length === 1) return splitHost[0]; // localhost?
  return [splitHost[splitHost.length - 2], splitHost[splitHost.length - 1]].join('.');
}

export function isThirdPartyUrl(url, firstPartyUrlPatterns = [urlToDomain(window.location.href)]) {
  try {
    if (!url) return false;
    if (url.startsWith('//')) url = `https:` + url; // sometimes script URLs are like //js-na1.hs-scripts.com/23547366.js
    return !firstPartyUrlPatterns.includes(urlToDomain(url));
  } catch(err) {
    // console.error(`Bad URL: ${url}, assuming it is first party.`)
    return false;
  }
}

export function getScriptTagLoadType(scriptTag) {
  return scriptTag.getAttribute('async') !== null ? 'async' :
          scriptTag.getAttribute('defer') !== null ? 'defer' : 'synchronous';
}