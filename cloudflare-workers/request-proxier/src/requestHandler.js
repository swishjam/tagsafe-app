import { AttributeRewriter } from './attributeRewriter.js';
import { ElementRemover } from './elementRemover.js';
import { HeadElementHandler } from './headElementHandler.js';

export async function handleRequest(request, env, _context) {
  const parsedRequestedUrl = new URL(request.url);
  const tagsafeProxyHost = env.TAGSAFE_PROXY_HOST;
  const requestedUrlParams = new URLSearchParams(parsedRequestedUrl.search);
  const originHostToFetchContentFrom = requestedUrlParams.get('tagsafe-origin-host') || env.ORIGIN_HOST;
  const originUrl = 'https://' + originHostToFetchContentFrom + parsedRequestedUrl.pathname + parsedRequestedUrl.search;
  console.log(`Re-routing request from ${request.url} to ${originUrl}...`);
  const init = { method: request.method, headers: [...request.headers] };
  const response = await fetch(originUrl, init);
  const contentType = response.headers.get('content-type') || response.headers.get('Content-Type');
  if (contentType && contentType.includes('text/html')) {
    const shouldProxyScriptSrcs = env.SHOULD_PROXY_SCRIPT_SRCS !== 'false';
    const shouldProxyLinkHrefs = env.SHOULD_PROXY_LINK_HREFS !== 'false';
    const shouldProxyImgSrcs = env.SHOULD_PROXY_IMG_SRCS !== 'false';
    const shouldInterceptInjectedElements = env.SHOULD_INTERCEPT_INJECTED_ELEMENTS !== 'false';
    const shouldRemoveDnsPrefetchLinks = env.SHOULD_REMOVE_DNS_PREFETCH_LINKS !== 'false';
    const shouldRemovePreconnectLinks = env.SHOULD_REMOVE_PRECONNECT_LINKS !== 'false';

    return new HTMLRewriter()
      .on('link[rel="dns-prefetch"]', new ElementRemover({ enabled: shouldRemoveDnsPrefetchLinks }))
      .on('link[rel="preconnect"]', new ElementRemover({ enabled: shouldRemovePreconnectLinks }))
      .on('script[src]', new AttributeRewriter({ 
        enabled: shouldProxyScriptSrcs, 
        attributeName: 'src', 
        tagsafeProxyHost, 
        originHostToFetchContentFrom 
      }))
      .on('link[href]', new AttributeRewriter({ 
        enabled: shouldProxyLinkHrefs, 
        attributeName: 'href', 
        tagsafeProxyHost, 
        originHostToFetchContentFrom 
      }))
      .on('style[data-href]', new AttributeRewriter({
        enabled: shouldProxyLinkHrefs,
        attributeName: 'data-href',
        tagsafeProxyHost,
        originHostToFetchContentFrom
      }))
      .on('img[src]', new AttributeRewriter({ 
        enabled: shouldProxyImgSrcs, 
        attributeName: 'src', 
        tagsafeProxyHost, 
        originHostToFetchContentFrom 
      }))
      .on('head', new HeadElementHandler({ 
        enabled: shouldInterceptInjectedElements, 
        tagsafeProxyHost, 
        originHostToFetchContentFrom 
      }))
      .transform(response);
  } else {
    return response;
  }
}