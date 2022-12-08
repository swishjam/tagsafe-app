class MonkeyPatcher {
  constructor(thirdPartyTagDetector) {
    this.thirdPartyTagDetector = thirdPartyTagDetector;
    this.stripAllJS = false;
  }

  addMonkeyPatchScriptToCheerioDOM = cheerioDOM => {
    console.log(`Prepending monkey patch script tag to intercept injected tags.`);
    cheerioDOM("head").prepend(`<script>${this._newNodeInterceptionMonkeyPatch()}</script>`);
    // cheerioDOM("head").prepend(`<script>${this._webVitalsListeners()}</script>`);
    // cheerioDOM("head").prepend(`<script>${this._longRunningTasks()}</script>`);
  }

  _webVitalsListeners = () => {
    return `
      (function() {
        try {
          getCLS(function(data) {
            console.log("TAGSAFE_LOG_EVENT::WEB_VITALS_CLS::"+data);
          })
          getFID(function(data) {
            console.log("TAGSAFE_LOG_EVENT::WEB_VITALS_FID::"+data);
          })
          getLCP(function(data) {
            console.log("TAGSAFE_LOG_EVENT::WEB_VITALS_LCP::"+data);
          })
          console.log("TAGSAFE_EVENT_LOG::LOG::Setup web vitals listeners successfully");
        } catch(e) {
          console.log("TAGSAFE_EVENT_LOG::LOG::Failed to setup web vitals: "+e);
        }
      })()
    `;
  }

  _longRunningTasks = () => {
    return `
      (function() {
        try {
          var observer = new PerformanceObserver(function(list) {
            try {
              var perfEntries = list.getEntries();
              for (var i = 0; i < perfEntries.length; i++) {
                console.log("TAGSAFE_LOG_EVENT::LONG_RUNNING_TASK::"+JSON.stringify(perfEntries[0]));
              }
            } catch(e) {
              console.log("TAGSAFE_EVENT_LOG::LOG::Failed to setup long running task listeners");
            }
          });
          observer.observe({entryTypes: ["longtask"]});
          console.log("TAGSAFE_EVENT_LOG::LOG::Setup long running task listener successfully");
        } catch(e) {
          console.log("TAGSAFE_EVENT_LOG::LOG::Failed to setup long running task listeners");
        }
      })()
    `;
  }

  _newNodeInterceptionMonkeyPatch = () => {
    return `
      (function() {
        try {
          var urlsToAllow = ${JSON.stringify(this.thirdPartyTagDetector.urlPatternsToAllow)};
          var stripAllJS = ${this.stripAllJS};
          function _hostnameForUrl (urlString) {
            return new URL(urlString).hostname
          };
          function _domainForUrl(url) {
            var splitUrlHost = _hostnameForUrl(url).split(".");
            splitUrlHost.shift();
            return splitUrlHost.join(".");
          };
          function isThirdPartyUrl(url) {
            if(url.slice(0, 2) == "//") url = "https://"+url;
            var isFirstPartyRelativePath = url[0] === "/";
            if(isFirstPartyRelativePath) {
              return false;
            } else {
              if(${process.env.CONSIDER_SUBDOMAINS_FIRST_PARTY === "true"}) {
                var isFirstPartyFullPath = _hostnameForUrl(url) === _hostnameForUrl(window.location.href);
                return !isFirstPartyFullPath;
              } else {
                var isFirstPartyFullPath = _domainForUrl(url) === _domainForUrl(window.location.href);
                return !isFirstPartyFullPath;
              }
            }
          };
          function isAllowedUrl(url) {
            return ${this.thirdPartyTagDetector.allowAllThirdPartyTags} || urlsToAllow.some(urlPattern => url.includes(urlPattern))
          };
          function handleNewNode(newNode, allowNodeCallback) {
            if(newNode.nodeName === "SCRIPT") {
              var tagUrl = newNode.getAttribute("src");
              if(stripAllJS || tagUrl) {
                if(stripAllJS || isThirdPartyUrl(tagUrl)) {
                  if(tagUrl && isAllowedUrl(tagUrl)) {
                    console.log("TAGSAFE_LOG_EVENT::LOG::Allowing "+tagUrl+" to be injected: "+newNode);
                    console.log("TAGSAFE_LOG_EVENT::THIRD_PARTY_TAG_ALLOWED::"+tagUrl);
                    allowNodeCallback();
                  } else {
                    console.log("Disabling third party tag: "+tagUrl);
                    console.log("TAGSAFE_LOG_EVENT::RESOURCE_BLOCKED::"+tagUrl+"::script");
                  }
                }
              } else {
                console.log("TAGSAFE_LOG_EVENT::LOG::Allowing empty script tag to be injected: "+newNode);
                allowNodeCallback();
              }
            } else {
              allowNodeCallback();
            }
          };
          var ogAppendChild = Node.prototype.appendChild;
          Node.prototype.appendChild = function() {
            handleNewNode(arguments[0], () => ogAppendChild.apply(this, arguments));
          };
          var ogInsertBefore = Node.prototype.insertBefore;
          Node.prototype.insertBefore = function() {
            handleNewNode(arguments[0], () => ogInsertBefore.apply(this, arguments));
          };
          var ogPrepend = Node.prototype.prepend;
          Node.prototype.prepend = function() {
            handleNewNode(arguments[0], () => ogPrepend.apply(this, arguments));
          };
          console.log("TAGSAFE_LOG_EVENT::LOG::Added script interception monkey patch successfully");
        } catch(e) {
          console.log("TAGSAFE_LOG::LOG::ERROR ENCOUNTERED IN MONKEY PATCH SCRIPT: "+e);
        }
      })();
    `;
  }
}

module.exports = MonkeyPatcher;