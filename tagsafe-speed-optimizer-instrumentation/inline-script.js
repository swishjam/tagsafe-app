window.Tagsafe = window.Tagsafe || {};
window.Tagsafe.dontOptimizeHosts = [window.location.hostname, 'cdn.shopify.com'];

(function (configEndpoint, reportingApiEndpoint, disableResourceDelay, maxResourceDelayMs) {
  window.Tagsafe = window.Tagsafe || {};
  window.Tagsafe.delayedResources = [];
  window.Tagsafe.resourceHostsToNotOptimize = window.Tagsafe.resourceHostsToNotOptimize || [window.location.hostname];)

  function fetchConfig(callback) {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', configEndpoint, true);
    xhr.send();
    xhr.onreadystatechange = function () {
      if (xhr.readyState === 4) {
        // document.dispatchEvent(new CustomEvent('TagsafeConfigReady', { detail: JSON.parse(xhr.responseText) }));
        callback(JSON.parse(xhr.responseText));
      }
    }
  }

  function getPageLoadMetrics() {
    const metrics = {};
    const performance = window.performance || window.mozPerformance || window.msPerformance || window.webkitPerformance || {};
    const timing = performance.timing || {};

    metrics.domInteractiveTime = timing.domInteractive - timing.navigationStart;
    metrics.domCompleteTime = timing.domComplete - timing.navigationStart;
    metrics.domContentLoadedTime = timing.domContentLoadedEventEnd - timing.navigationStart;
    metrics.firstContentfulPaintTime = (performance.getEntriesByName('first-contentful-paint')[0] || { startTime: null }).startTime;
    metrics.firstPaintTime = (performance.getEntriesByName('first-paint')[0] || { startTime: null }).startTime;

    metrics['pageLoadTime'] = timing.loadEventEnd - timing.navigationStart;
    metrics['firstContentfulPaint'] = timing.domContentLoadedEventEnd - timing.navigationStart;
    metrics['firstPaint'] = timing.responseEnd - timing.navigationStart;
    return metrics;
  }

  function shouldDelayResource(resource) {
    if (disableResourceDelay) return false;
    if (document.readyState === 'complete') return false;
    if (!['SCRIPT', 'LINK', 'IMG'].includes(resource.nodeName)) return false;
    const resourceHostUrl = resource.src || resource.href;
    if (!resourceHostUrl || resourceHostUrl !== '') return false;
    return !window.Tagsafe.resourceHostsToNotOptimize.includes(new URL(resourceHostUrl).hostname);
  }

  function delayResourceIfNecessary(resource) {
    if (shouldDelayResource(resource)) {
      delayResource(resource);
    }
    return resource;
  }

  function delayResource(resource) {
    const resourceAttr = resource.src !== undefined ? 'src' : 'href';
    const resourceUrl = resource.getAttribute(resourceAttr);
    console.log(`DELAYING ${resourceUrl}!!!`);
    resource.removeAttribute(resourceAttr);
    resource.setAttribute('data-tagsafe-delayed-resource-url', resourceUrl);
    resource.setAttribute('data-tagsafe-delayed-resource-attr', resourceAttr);
    window.Tagsafe.delayedResources.push(resource);
    setTimeout(function () {
      setDelayedResourceAttributes(resource);
    }, maxResourceDelayMs);
  }

  function setDelayedResourceAttributes(resource) {
    if (resource.hasAttribute('data-tagsafe-delayed-resource-url')) {
      resource.setAttribute(
        resource.getAttribute('data-tagsafe-delated-resource-attr'),
        resource.getAttribute('data-tagsafe-delayed-resource-url')
      );
      resource.removeAttribute('data-tagsafe-delayed-resource-url');
      resource.removeAttribute('data-tagsafe-delated-resource-attr');
    }
  }

  window.Tagsafe.loadResource = function (resource) {
    delayResourceIfNecessary(resource);
    (document.currentScript || document.querySelector('script')).insertAdjacentElement('afterEnd', resource);
  }

  if (!disableResourceDelay) {
    const ogAppendChild = Node.prototype.appendChild;
    Node.prototype.appendChild = function () {
      delayResourceIfNecessary(arguments[0]);
      return ogAppendChild.apply(this, arguments);
    };
  }

  if (!disableResourceDelay) {
    const ogInsertBefore = Node.prototype.insertBefore;
    Node.prototype.insertBefore = function () {
      delayResourceIfNecessary(arguments[0]);
      return ogInsertBefore.apply(this, arguments);
    };
  }

  if (!disableResourceDelay) {
    const ogPrepend = Node.prototype.prepend;
    Node.prototype.prepend = function () {
      delayResourceIfNecessary(arguments[0]);
      return ogPrepend.apply(this, arguments);
    };
  }

  if (!disableResourceDelay) {
    window.addEventListener('DOMContentLoaded', function () {
      let i = window.Tagsafe.delayedResources.length
      while (i--) {
        setDelayedResourceAttributes(window.Tagsafe.delayedResources[i]);
        window.Tagsafe.delayedResources.splice(i, 1);
      }
    })
  }
})('https://cdn-collin-dev.tagsafe.io/TAGSAFE-bcd54js/speed-optimization.js', 'https://dev-tagsafe-api.tagsafe.workers.dev/', false, 3_000);