class DomManipulator {
  setPage = page => {
    this.page = page;
  }

  displayFunctionCalledNotification = async (functionName, ...functionArgs) => {
    const uniqueId = `${functionName}-${functionArgs.join('-')}`;
    const message = `TS.PAGE.${functionName} called with ${functionArgs.join(', ')}...`;
    console.log(`Displaying function called notification for function ${uniqueId}`);
    await this.page.evaluate((_notificationExemptMsg, domId, msg) => {
      let container = document.getElementById('tagsafe-notification-container');
      if(!container) {
        container = document.createElement('div');
        container.id = 'tagsafe-notification-container';
        container.style = `
          position: fixed;
          z-index: 100000000;
          top: 20px;
          right: 20px;
          width: 20vw;
        `;
        document.body.appendChild(container);
      }
      const notification = document.createElement('div');
      notification.id = domId;
      notification.textContent = msg;
      notification.style = `
        width: 100%;
        border-radius: 10px;
        font-size: 26px;
        font-weight: 600;
        margin: 10px;
        padding: 15px;
        background: darkgrey;
        color: white;
        text-align: center;
      `;
      container.appendChild(notification);
    }, 'bypass-function-notification', uniqueId, message);
  }

  displayFunctionRespondedNotification = async (functionName, response, ...functionArgs) => {
    const uniqueId = `${functionName}-${functionArgs.join('-')}`;
    let message;
    if(response) {
      message = `TS.PAGE.${functionName} responded with ${response.toString()}.`;
    } else {
      message = `TS.PAGE.${functionName} completed.`
    }
    console.log(`Displaying function responded notification for ${uniqueId}`);
    await this.page.evaluate((_notificationExemptMsg, domId, msg) => {
      const notification = document.getElementById(domId);
      if(notification) {
        notification.textContent = msg;
        notification.style.background = 'lightgreen'
        setTimeout(() => {
          notification.remove();
        }, 2000);
      }
    }, 'bypass-function-notification', uniqueId, message);
  }

  displayResultsMessage = async ({ message, success }) => {
    if(!this.page) throw Error('DomManipulator does not have page set.');
    await this.page.evaluate((_notificationExemptMsg, msg, fontColor) => {
      if(document.body) {
        const msgDiv = document.createElement('div');
        const msgBackdrop = document.createElement('div');
        msgBackdrop.style = `
          height: 100vh;
          width: 100vw;
          background: rgba(0, 0, 0, 0.3);
          display: flex;
          align-items: center;
          justify-content: center;
          position: fixed;
          top: 0;
          left: 0;
          z-index: 1000000;
        `;
        msgDiv.style = `
          height: 40vh;
          width: 40vw;
          padding: 20px;
          background: white;
          border-radius: 10px;
          color: ${fontColor};
          font-size: 40px;
          font-weight: 600;
          display: flex;
          align-items: center;
          justify-content: center;
          text-align: center;
          position: fixed;
          z-index: 1000001;
        `;
        msgDiv.textContent = msg;
        msgBackdrop.appendChild(msgDiv);
        document.body.appendChild(msgBackdrop);
      }
    }, 'bypass-function-notification', message, success ? 'green' : 'red');
  }

  addInteractionsAmplifiers = async () => {
    if(!this.page) throw Error('DomManipulator does not have page set.');
    await this.page.evaluateOnNewDocument(() => {
      if(window !== window.parent) return;
      const styleEl = document.createElement('style');

      styleEl.innerHTML = `
        div.clickEffect {
          position: fixed;
          box-sizing: border-box;
          border-style: solid;
          border-color: black;
          border-radius: 50%;
          animation: clickEffect 0.4s ease-out;
          z-index: 99999;
        }
        
        @keyframes clickEffect {
          0% {
            opacity: 1;
            width: 0.5em; 
            height: 0.5em;
            margin: -0.25em;
            border-width: 5px;
          }
          100% {
            opacity: 0.2;
            width: 15em;
            height: 15em;
            margin: -7.5em;
            border-width: 0.03em;
          }
        }
      `;
      function clickEffect(e){
        var el = document.createElement("div");
        el.className= "clickEffect";
        el.style.top= e.clientY+"px";
        el.style.left= e.clientX+"px";
        document.body.appendChild(el);
        el.addEventListener('animationend', () => el.parentElement.removeChild(el) );
      }
      document.addEventListener('mousedown', clickEffect);
      
      if(document.head) {
        document.head.appendChild(styleEl);
      } else {
        let waitForHeadInterval = setInterval(() => {
          if(document.head) {
            document.head.appendChild(styleEl);
            clearInterval(waitForHeadInterval);
          }
        }, 1);
      }
    })
  }
}

module.exports = DomManipulator;