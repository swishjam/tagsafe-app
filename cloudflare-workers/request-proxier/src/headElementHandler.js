export class HeadElementHandler {
  constructor({ enabled, originHostToFetchContentFrom, tagsafeProxyHost }) {
    this.enabled = enabled;
    this.originHostToFetchContentFrom = originHostToFetchContentFrom;
    this.tagsafeProxyHost = tagsafeProxyHost;
  }

  element(element) {
    if (!this.enabled) return;
    element.prepend(`
      <script data-tagsafe-proxier>
        (function() {
          const ogAppendChild = Node.prototype.appendChild;
          Node.prototype.appendChild = function() {
            if((arguments[0].href || arguments[0].src) && arguments[0].tagName !== 'A') {
              reWriteResourceElement(arguments[0]);
            }
            return ogAppendChild.apply(this, arguments);
          };

          const ogInsertBefore = Node.prototype.insertBefore;
          Node.prototype.insertBefore = function() {
            if((arguments[0].href || arguments[0].src) && arguments[0].tagName !== 'A') {
              reWriteResourceElement(arguments[0]);
            }
            return ogInsertBefore.apply(this, arguments);
          };

          const ogPrepend = Element.prototype.prepend;
          Element.prototype.prepend = function() {
            if((arguments[0].href || arguments[0].src) && arguments[0].tagName !== 'A') {
              reWriteResourceElement(arguments[0]);
            }
            return ogPrepend.apply(this, arguments);
          };

          function reWriteResourceElement(element) {
            const resourceAttr = ![undefined, ''].includes(element.href) ? 'href' : ![undefined, ''].includes(element.src) ? 'src' : null;
            if(resourceAttr) {
              const ogSrc = element.getAttribute(resourceAttr);
              if(ogSrc.startsWith('//')) ogSrc = 'https:' + ogSrc;
              if(ogSrc.startsWith('/')) ogSrc = 'https://${this.originHostToFetchContentFrom}' + ogSrc;
              if(!ogSrc.startsWith('http')) ogSrc = 'https://${this.originHostToFetchContentFrom}/' + ogSrc;
              const ogParsedSrc = new URL(ogSrc);
              const searchParams = new URLSearchParams(ogParsedSrc.search);
              searchParams.set('tagsafe-origin-host', ogParsedSrc.hostname);
              const reWrittenAttr = 'https://${this.tagsafeProxyHost}' + ogParsedSrc.pathname + '?' + searchParams.toString();
              element.setAttribute(resourceAttr, reWrittenAttr);
              element.setAttribute('data-tagsafe-intercepted', 'true');
              console.log('Rewrote script src attribute from ' + ogSrc + ' to ' + reWrittenAttr + '...');
            }
          }
        })();
      </script>
    `, { html: true });
  }
}