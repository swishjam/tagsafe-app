export default {
  async fetch(request, env, _context) {
    const parsedRequestedUrl = new URL(request.url);
    const tagsafeProxyHost = env.TAGSAFE_PROXY_HOST || 'tagsafe-proxy.tagsafe.io';
    const defaultOriginHost = env.ORIGIN_HOST || 'www.tagsafe.io';
    const originUrl = 'https://' + defaultOriginHost + parsedRequestedUrl.pathname + parsedRequestedUrl.search;
    console.log(`Re-routing request from ${request.url} to ${originUrl}...`);
    console.log(JSON.stringify(request.headers))
    const init = {
      method: request.method,
      redirect: "manual",
      headers: [...request.headers]
    };
    const response = await fetch(originUrl, init);
    if (response.headers.get('content-type').includes('text/html')) {
      return new HTMLRewriter()
              .on('script[src]', new AttributeRewriter({
                attributeName: 'src', 
                tagsafeProxyHost,
                defaultOriginHost,
              }))
              .on('link[href]', new AttributeRewriter({
                attributeName: 'href',
                tagsafeProxyHost,
                defaultOriginHost,
              }))
              .on('img[src]', new AttributeRewriter({
                attributeName: 'src', 
                tagsafeProxyHost,
                defaultOriginHost,
              }))
              .on('head', el => {
                console.log('HEAD!!!');
                const scriptTag = document.createElement('script');
                scriptTag.setAttribute('tagsafe-proxyier', 'true');
                scriptTag.innerHTML = `
                  const ogAppendChild = Node.prototype.appendChild;
                  const scope = this;
                  Node.prototype.appendChild = function() {
                    if(arguments[0].tagName === 'SCRIPT') {
                      arguments[0].setAttribute('data-tagsafe-intercepted', 'true');
                      if(arguments[0].getAttribute('src)) {
                        const ogSrc = arguments[0].getAttribute('src');
                        if(ogSrc.startsWith('//')) ogSrc = 'https:' + ogSrc;
                        if(ogSrc.startsWith('/')) ogSrc = 'https://${defaultOriginHost}' + ogSrc;
                        if(!ogSrc.startsWith('http')) ogSrc = 'https://${defaultOriginHost}/' + ogSrc;
                        const ogParsedSrc = new URL(ogSrc);
                        const searchParams = new URLSearchParams(ogParsedSrc.search);
                        searchParams.set('tagsafe-origin-host', ogParsedSrc.hostname);
                        const reWrittenAttr = 'https://${tagsafeProxyHost}' + ogParsedSrc.pathname + '?' + searchParams.toString();
                        arguments[0].setAttribute('src', reWrittenAttr);
                        console.log('Rewrote script src attribute from ' + ogSrc + ' to ' + reWrittenAttr + '...');
                      }
                    }
                    return ogAppendChild.apply(this, arguments);
                  };
                `
                console.log(`Added script tag to head...!!!`);
                el.appendChild(scriptTag);
              })
              .transform(response);
    } else {
      return response;
    }
  }
}

class AttributeRewriter {
  constructor({ attributeName, defaultOriginHost, tagsafeProxyHost }) {
    this.attributeName = attributeName;
    this.defaultOriginHost = defaultOriginHost;
    this.tagsafeProxyHost = tagsafeProxyHost;
  }

  element(element) {
    let attributeValue = element.getAttribute(this.attributeName);
    if (attributeValue) {
      console.log(`attributeValue: ${attributeValue}...`);
      if(attributeValue.startsWith('//')) attributeValue = `https:${attributeValue}`;
      if(attributeValue.startsWith('/')) attributeValue = `https://${this.defaultOriginHost}${attributeValue}`;
      if(!attributeValue.startsWith('http')) attributeValue = `https://${this.defaultOriginHost}/${attributeValue}`;
      const ogParsedSrc = new URL(attributeValue);
      const searchParams = new URLSearchParams(ogParsedSrc.search);
      searchParams.set('tagsafe-origin-host', ogParsedSrc.hostname);
      const reWrittenAttr = `https://${this.tagsafeProxyHost}${ogParsedSrc.pathname}?${searchParams.toString()}`;
      console.log(`Rewrote ${this.attributeName} attribute from ${attributeValue} to ${reWrittenAttr}...`);
      element.setAttribute(this.attributeName, reWrittenAttr);
    } else {
      console.error(`Attribute ${this.attributeName} not found on element ${element.tagName}`)
    }
  }
}