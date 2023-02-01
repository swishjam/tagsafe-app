export class AttributeRewriter {
  constructor({ enabled, attributeName, originHostToFetchContentFrom, tagsafeProxyHost }) {
    this.enabled = enabled;
    this.attributeName = attributeName;
    this.originHostToFetchContentFrom = originHostToFetchContentFrom;
    this.tagsafeProxyHost = tagsafeProxyHost;
  }

  element(element) {
    if(!this.enabled) return;
    let attributeValue = element.getAttribute(this.attributeName);
    if (attributeValue) {
      if (attributeValue.startsWith('//')) attributeValue = `https:${attributeValue}`;
      if (attributeValue.startsWith('/')) attributeValue = `https://${this.originHostToFetchContentFrom}${attributeValue}`;
      if (!attributeValue.startsWith('http')) attributeValue = `https://${this.originHostToFetchContentFrom}/${attributeValue}`;
      const ogParsedSrc = new URL(attributeValue);
      const searchParams = new URLSearchParams(ogParsedSrc.search);
      searchParams.set('tagsafe-origin-host', ogParsedSrc.hostname);
      const reWrittenAttr = `https://${this.tagsafeProxyHost}${ogParsedSrc.pathname}?${searchParams.toString()}`;
      console.log(`Rewrote ${element.tagName}'s ${this.attributeName} attribute from ${attributeValue} to ${reWrittenAttr}...`);
      element.setAttribute(this.attributeName, reWrittenAttr);
      element.setAttribute('data-tagsafe-original-url', attributeValue);
    } else {
      console.error(`Attribute ${this.attributeName} not found on element ${element.tagName}`)
    }
  }
}