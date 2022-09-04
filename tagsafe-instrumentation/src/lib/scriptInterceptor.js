export default class ScriptInterceptor {
  constructor(urlsToInterceptMap) {
    this.urlsToInterceptMap = urlsToInterceptMap;
    window.Tagsafe.interceptedTags = [];
  }

  interceptInjectedScriptTags = () => {
    this._interceptAppendChild();
    this._interceptInsertBefore();
    this._interceptPrepend();
  }

  _interceptAppendChild = () => {
    const ogAppendChild = Node.prototype.appendChild;
    const urlsToInterceptMap = this.urlsToInterceptMap;
    Node.prototype.appendChild = function() {
      try {
        const newNode = arguments[0];
        if(newNode.nodeName === 'SCRIPT') {
          const urlToRemapTo = urlsToInterceptMap[newNode.getAttribute('src')];
          if(urlToRemapTo) {
            console.log(`Intercepting Script node ${newNode.getAttribute('src')} -> ${urlToRemapTo}`);
            window.Tagsafe.interceptedTags.push(newNode.getAttribute('src'));
            arguments[0].src = urlToRemapTo;
          }
        }
        return ogAppendChild.apply(this, arguments);
      } catch(err) {
        console.error(`Tagsafe intercept error: ${err}`);
        return ogAppendChild.apply(this, arguments);
      }
    };
  }

  _interceptInsertBefore = () => {
    const ogInsertBefore = Node.prototype.insertBefore;
    const urlsToInterceptMap = this.urlsToInterceptMap;
    Node.prototype.insertBefore = function() {
      try {
        const newNode = arguments[0];
        if(newNode.nodeName === 'SCRIPT') {
          const urlToRemapTo = urlsToInterceptMap[newNode.getAttribute('src')];
          if(urlToRemapTo) {
            console.log(`Intercepting Script node ${newNode.getAttribute('src')} -> ${urlToRemapTo}`);
            window.Tagsafe.interceptedTags.push(newNode.getAttribute('src'));
            arguments[0].src = urlToRemapTo;
          }
        }
        return ogInsertBefore.apply(this, arguments);
      } catch(err) {
        console.error(`Tagsafe intercept error: ${err}`);
        return ogInsertBefore.apply(this, arguments);
      }
    };
  }

  _interceptPrepend = function() {
    const ogPrepend = Node.prototype.prepend;
    const urlsToInterceptMap = this.urlsToInterceptMap;
    Node.prototype.prepend = function() {
      try {
        const newNode = arguments[0];
        if(newNode.nodeName === 'SCRIPT') {
          const urlToRemapTo = urlsToInterceptMap[newNode.getAttribute('src')];
          if(urlToRemapTo) {
            console.log(`Intercepting Script node ${newNode.getAttribute('src')} -> ${urlToRemapTo}`);
            window.Tagsafe.interceptedTags.push(newNode.getAttribute('src'));
            arguments[0].src = urlToRemapTo;
          }
        }
        return ogPrepend.apply(this, arguments);
      } catch(err) {
        console.error(`Tagsafe intercept error: ${err}`);
        return ogPrepend.apply(this, arguments);
      }
    };
  }

  // _urlToRemapNodeTo = node => {
  //   if(node.nodeName === 'SCRIPT') {
  //     console.log(`Is ${node.getAttribute('src')} in?`)
  //     console.log(this.urlsToInterceptMap);
  //     const urlToRemap = this.urlsToInterceptMap[node.getAttribute('src')];
  //     return typeof urlToRemap === 'string' && urlToRemap;
  //   }
  // }

    // _monkeyPatchMethod = ({ originalMethod, scope, providedArguments }) => {
  //   const newNode = providedArguments[0];
  //   const urlToRemap = this._urlToRemapNodeTo(newNode);
  //   if(urlToRemap) providedArguments[0].src = urlToRemap;
  //   originalMethod.apply(scope, providedArguments)
  // }
}