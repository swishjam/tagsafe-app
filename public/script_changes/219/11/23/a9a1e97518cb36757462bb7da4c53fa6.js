(function () {
    if (typeof window._ltk.Signup !== 'undefined' && !(window._ltk.Signup instanceof Array)) return;

    window._ltk.Signup = new _LTKSubscriber();


})();


(function () {
    var version = "0.2.5.1";
    var comment = "Fixed misspelled variables;"
	+ " Added SetDateFields, SetBirthdayFields, SetAnniversaryFields;"
    + " Added LtkSubscriberLoad event trigger;"
    + " Check Order.SessionID for checkout;"
    + " Fix button selector to accept ID wihtout #;"
    + " Changed to ltk.Signup"
    + " bug fixes";
    + " modified to allow id/name/queryselector for button instead of just queryselector/id";
    + " Official Release 1/19/17 - DMG";
    + " Fixed bug where ltkSaved true was set on SubscribeFromTrigger instead of button event and";
    + " added simple @ email validation 1/20/17 - DMG";
    

    _LTKSubscriber.prototype.GetVersion = function () { return "Version " + version + ": " + comment; }
    _LTKSubscriber.prototype.GetSavedSubscriberData = function () { return getSavedSubscriberData(); }
    _LTKSubscriber.prototype.GetSubscriptionKeys = function () {
        var data = _ltk.Subscriber.GetSavedSubscriberData();
        var lists = data.lists;
        _ltk_util.consoleLog("Field names to map in Listrak Platform:")
        for (var list in lists) {
            _ltk_util.consoleLog("Subscription point: " + list);
            var props = lists[list];
            for (var prop in props) {
                if (prop.indexOf("ltk") != 0) _ltk_util.consoleLog("   Field name: " + prop);
            }
            _ltk_util.consoleLog("   Field name: ltkSource");
        }
    }

    //////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////
    /////////////  Client simplification code ///////////////
    //////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////

    _LTKSubscriber.prototype.TYPE = Object.freeze({
        DEFAULT: "load",
        CHECKOUT: "checkout",
        CLICK: "click",
        CUSTOM: "trigger"
    });

    _LTKSubscriber.prototype.New = function (subscriber_code, id, type, button) {
        if (subscriber_code == null || typeof (subscriber_code) == "undefined") { _ltk.Exception.Submit("subscriber_code param cannot be null or undefined"); }
        if (id == null || typeof (id) == "undefined") { _ltk.Exception.Submit("id param cannot be null or undefined"); }
        if (type == null || typeof (type) == "undefined") { _ltk.Exception.Submit("type param cannot be null. Please use one of the types in the _ltk.Signup.TYPE enumerator."); }
        if ((type == this.TYPE.CLICK || type == this.TYPE.DEFAULT) && (button == null || typeof (button) == 'undefined')) {
            _ltk.Exception.Submit("Function parameter 'button' cannot be null or undefined if using CLICK or DEFAULT enumerator.");
        }

        if (_ltk.SCA)
            _ltk.SCA.CaptureEmail(id);

        switch (type) {
            case this.TYPE.DEFAULT:
                setEmailWithTrigger(subscriber_code, id, "load");
                setButtonClick(subscriber_code, button);
                break;
            case this.TYPE.CHECKOUT:
                setEmailWithTrigger(subscriber_code, id, "checkout");
                setSubmit(subscriber_code);
                break;
            case this.TYPE.CLICK:
                setEmailWithTrigger(subscriber_code, id, "load");
                appendSubmitEvent(subscriber_code, button, 'click');
                break;
            case this.TYPE.CUSTOM:
                setEmailWithTrigger(subscriber_code, id, type);
                break;
            default:
                _ltk.Exception.Submit("type enum not recognized!");
                break;
        }
    }

    _LTKSubscriber.prototype.Remove = function (subscriber_code, id, type, button) {
        if (subscriber_code == null || typeof (subscriber_code) == "undefined") {
            _ltk.Exception.Submit("subscriber_code param cannot be null or undefined");
        }
        if (id == null || typeof (id) == "undefined") {
            _ltk.Exception.Submit("id param cannot be null or undefined");
        }
        if (type == null || typeof (type) == "undefined") {
            _ltk.Exception.Submit("type param cannot be null. Please use one of the types in the _ltk.Signup.TYPE enumerator.");
        }
        if ((type == this.TYPE.CLICK || type == this.TYPE.DEFAULT) && (button == null || typeof (button) == 'undefined')) {
            _ltk.Exception.Submit("Function parameter 'button' cannot be null or undefined if using Click enumerator.");
        }

        switch (type) {
            case this.TYPE.DEFAULT:
                setUnsubscribeEmailWithTrigger(subscriber_code, id, 'load');
                setButtonClick(subscriber_code, button);
                break;
            case this.TYPE.CLICK:
                setUnsubscribeEmailWithTrigger(subscriber_code, id, 'load');
                appendSubmitEvent(subscriber_code, button, 'click');
                break;
            case this.TYPE.CUSTOM:
                setUnsubscribeEmailWithTrigger(subscriber_code, id, type);
                break;
            default:
                _ltk.Exception.Submit("type enum not recognized!");
                break;
        }
    }
    _LTKSubscriber.prototype.SubscribeFromTrigger = function (trigger) {
        SubscribeFromTrigger(trigger);
    }
    _LTKSubscriber.prototype.SetSubmitEvent = function (subscriber_code, element, event) {
        appendSubmitEvent(subscriber_code, element, event);
    }

    function isValidEmail(email) {
        return email !== "" && email.includes("@");
    }

    ////// END SIMPLIFICATION CODE //////



    _LTKSubscriber.prototype.SetUnsubscribeEmailWithButtonClick = function (subscriber_code, element, selector) {
        setUnsubscribeEmailWithTrigger(subscriber_code, id, 'load');
        setButtonClick(subscriber_code, selector);
    }

    _LTKSubscriber.prototype.SetEmailValue = function (subscriber_code, value) {
        setEmailValueWithTrigger(subscriber_code, value, "load");
    }

    _LTKSubscriber.prototype.SetUpdateEmail = function (subscriber_code, id) {
        setField(subscriber_code, id, { key: "ltkUpdateEmail" });
    }
    _LTKSubscriber.prototype.SetOptIn = function (subscriber_code, id) {
        setField(subscriber_code, id, { key: "ltkOptIn" });
    }
    _LTKSubscriber.prototype.SetOptOut = function (subscriber_code, id) {
        setField(subscriber_code, id, { key: "ltkOptOut" });
    }

    _LTKSubscriber.prototype.SetDateFields = function (subscriber_code, key, month, day, year) {
        setDateFields(subscriber_code, key, month, day, year);
    }
    _LTKSubscriber.prototype.SetBirthdayFields = function (subscriber_code, month, day, year) {
        setDateFields(subscriber_code, "birthday", month, day, year);
    }
    _LTKSubscriber.prototype.SetAnniversaryFields = function (subscriber_code, month, day, year) {
        setDateFields(subscriber_code, "anniversary", month, day, year);
    }

    _LTKSubscriber.prototype.SetForceOverride = function (subscriber_code, forceOverride) {
        setForceOverride(subscriber_code, forceOverride);
    }
    _LTKSubscriber.prototype.SetTrigger = function (subscriber_code, trigger) {
        setTrigger(subscriber_code, trigger);
    }
    _LTKSubscriber.prototype.SetValueFromQueryString = function (subscriber_code, key) {
        var value = _ltk_util.getQuerystringValue(key);
        setValue(subscriber_code, key, value);
    }

    _LTKSubscriber.prototype.SetField = function (subscriber_code, id, options) {
        setField(subscriber_code, id, options);
    }
    _LTKSubscriber.prototype.SetFieldWithKey = function (subscriber_code, id, key) {
        setField(subscriber_code, id, { key: key });
    }
    _LTKSubscriber.prototype.SetValue = function (subscriber_code, key, value) {
        setValue(subscriber_code, key, value);
    }

    _LTKSubscriber.prototype.Subscribe = function (subscriber_code, forceOverride) {
        setForceOverride(subscriber_code, forceOverride);
        SubscribeToList(subscriber_code);
    }

    appendEvent(document, "ltkCheckout", function () { SubscribeFromTrigger("checkout"); });
    _ltk_util.domready(function () {
        SubscribeFromTrigger("load");
        if (_ltk.Order.OrderNumber) { SubscribeFromTrigger("checkout"); }
        else { _ltk_util.consoleLog(_ltk.Order); }
    });

    // Revisions to appendEvent function:
    //      We should be trying to append events using jQuery first, as the on/live/bind
    //      functions offer more functionality and could prevent bugs relating to page structures
    //      and/or ajax. - JGP
    //
    //      Also fixed bug where jQuery functions were trying to be referenced
    //      via element.on/ element.live/ element.bind instead of the correct
    //      syntax of jQuery(element).on/ jQuery(element).live/ jQuery(element).bind - JGP
    function appendEvent(element, event, func) {
        if (!element) return;
        if (jQuery.on) { jQuery(element).on(event, func); }
        else if (jQuery.live) { jQuery(element).live(event, func); }
        else if (jQuery.bind) { jQuery(element).bind(event, func); }
        else if (element.addEventListener) { element.addEventListener(event, func, false); }
        else if (element.attachEvent) { element.attachEvent("on" + event, func); }
        else _ltk.Exception.Submit("Cannot attach to event: " + event, 'SubscriberAppendEvent-' + event);
    }

    function appendSubmitEvent(subscriber_code, element, event) {

        var selected = getElementsBySelector(element); // original        
        appendEvent(selected, event, function () {
            _ltk.Signup.SetValue(subscriber_code, "ltkSaved", true);
            _ltk.Signup.Subscribe(subscriber_code);
        });
    }

    function getElements(id) {
        var _sl;
        if (id.includes("[id=") || id.includes("[name=") || (id.includes("[") && id.includes("=")))
            _sl = jQuery(id);
        else
            _sl = jQuery("[id='" + id + "']");
        if (_sl.length == 0) { _sl = jQuery("[name='" + id + "']"); }
        return _sl;
    }
    function getElementsBySelector(selector) {
        var _sl = getElements(selector);
        if (_sl.length == 0) { _sl = jQuery(selector); }
        return _sl;
    }
    function getElementValue(elem, options) {
        if (elem.is("input[type='checkbox']")) return elem.is(':checked') ? "on" : "off";
        if (isGetRadioChecked(elem, options)) return elem.is(':checked') ? "on" : "off";
        if (isGetDropdownText(elem, options)) return elem.find(":selected").text();
        return elem.val();
    }

    function isGetRadioChecked(elem, options) { return elem.is("input[type='radio']") && options.radio == "checked"; }
    function isGetDropdownText(elem, options) { return elem.is("select") && options.dropdown == "text"; }
    function isValidSubscriber(subscriberData) {
        if (!subscriberData) return false;
        var Saved = (!subscriberData.ltkSaved) ? false : subscriberData.ltkSaved;
        var Email = (!subscriberData.ltkEmail) ? ((!subscriberData.ltkUnsubscribe) ? "" : subscriberData.ltkUnsubscribe) : subscriberData.ltkEmail;
        var OptIn = (!subscriberData.ltkOptIn) ? true : subscriberData.ltkOptIn == "on";
        var OptOut = (!subscriberData.ltkOptOut) ? false : subscriberData.ltkOptOut == "on";
        return Saved && isValidEmail(Email) && OptIn && !OptOut;
    }

    function setDefaultOptions(id, options) {
        var defaultOptions = (typeof options == "undefined") ? {} : options;
        if (!defaultOptions.key) defaultOptions.key = id;
        if (!defaultOptions.dropdown) defaultOptions.dropdown = "value";
        if (!defaultOptions.radio) defaultOptions.radio = "checked";
        return defaultOptions;
    }
    function convertMonthNameToNumber(month) {
        return new Date(Date.parse(month + " 1, 2016")).getMonth() + 1
    }
    function getDate(month, day, year) {
        if (typeof month === 'string') { month = convertMonthNameToNumber(month); };
        if (typeof month !== 'number') { return; };
        day = (typeof day === 'number') ? day : 1;
        year = (typeof year === 'number') ? year : new Date().getFullYear();
        return month + "/" + day + "/" + year;
    }

    function saveCookieData(name, data) {
        _ltk_util.setCookie(name, data, null, _ltk_util.getCookieDomain(), "/");
    }
    function getCookieData(name) {
        return _ltk_util.getCookie(name);
    }
    function deleteCookieData(name) {
        _ltk_util.deleteCookie(name, _ltk_util.getCookieDomain(), "/");
    }
    function saveCookieSubscriberData(subscriber_code, subscriberData) {
        var listData = JSON.stringify(subscriberData);
        saveCookieData("ltkSubscriber-" + subscriber_code, window.btoa(listData));
    }
    function getCookieSubscriberData(subscriber_code) {
        var listData = getCookieData("ltkSubscriber-" + subscriber_code);
        if (!listData) return {};
        var subscriberData = window.atob(listData);
        return JSON.parse(subscriberData);
    }
    function deleteCookieSubscriberData(subscriber_code) {
        deleteCookieData("ltkSubscriber-" + subscriber_code);
    }

    function getSavedSubscriberData() {
        var json = { lists: {} };
        var cookiePrefix = "ltkSubscriber-";
        var cookies = document.cookie.split("; ");
        for (var cookie in cookies) {
            var cookieData = cookies[cookie];
            if (typeof cookieData != "string") continue;
            var c_end = cookieData.indexOf("=");
            var cookieName = cookieData.substring(0, c_end);
            if (cookieData.indexOf(cookiePrefix) == 0) {
                var list = cookieName.replace(cookiePrefix, "");
                var subscriberData = getCookieSubscriberData(list);
                json.lists[list] = subscriberData;
            };
        }
        return json;
    }

    function setForceOverride(subscriber_code, forceOverride) {
        if (typeof forceOverride != "undefined") setValue(subscriber_code, "ltkForceOverride", forceOverride);
    }
    function setButtonClick(subscriber_code, selector) {
        var button = getElementsBySelector(selector);
        appendEvent(button, "click", function () { setSubmit(subscriber_code); });
    }
    function setField(subscriber_code, id, options) {
        CaptureSubscriberValue(subscriber_code, id, options);
    }
    function setValue(subscriber_code, key, value) {
        SetSubscriberValue(subscriber_code, key, value);
    }
    function setEmailWithTrigger(subscriber_code, id, trigger) {
        setTrigger(subscriber_code, trigger);
        setField(subscriber_code, id, { key: "ltkEmail" });
    }
    function setUnsubscribeEmailWithTrigger(subscriber_code, id, trigger) {
        setTrigger(subscriber_code, trigger);
        setField(subscriber_code, id, { key: "ltkUnsubscribe" });
    }
    function setEmailValueWithTrigger(subscriber_code, value, trigger) {
        setTrigger(subscriber_code, trigger);
        setValue(subscriber_code, "ltkEmail", value);
    }
    function setTrigger(subscriber_code, trigger) {
        if (typeof trigger == "undefined" || trigger == "") trigger = "trigger";
        setValue(subscriber_code, "ltkTrigger", trigger);
    }
    function setSubmit(subscriber_code) {
        setValue(subscriber_code, 'ltkSaved', true);
    }
    function setDateFields(subscriber_code, key, month, day, year) {
        var dateKey = "ltkDate-" + key;
        setField(subscriber_code, month, { key: dateKey, date: "month", dropdown: "text" });
        if (day) setField(subscriber_code, day, { key: dateKey, date: "day" });
        if (year) setField(subscriber_code, year, { key: dateKey, date: "year" });
    }

    function SubscribeToList(subscriber_code) {
        var subscriberData = getCookieSubscriberData(subscriber_code);
        SubmitSubscriber(subscriber_code, subscriberData);
    }

    function SubscribeFromTrigger(ltkTrigger) {
        var data = getSavedSubscriberData();
        var lists = data.lists;
        for (var list in lists) {
            var subscriberData = lists[list];
            //if (subscriberData.ltkTrigger == ltkTrigger)
             //   setValue(list, "ltkSaved", true);
        }
        data = getSavedSubscriberData();
        lists = data.lists;
        for (var list in lists) {
            var subscriberData = lists[list];
            if (subscriberData.ltkTrigger == ltkTrigger) {
                SubmitSubscriber(list, subscriberData);
            }
        }
    }

    function SubmitSubscriber(subscriber_code, subscriberData) {
        if (!isValidSubscriber(subscriberData)) return;
        _ltk_util.consoleLog(subscriberData);
        var Unsub = (!subscriberData.ltkUnsubscribe) ? false : true;
        var wasSubmitted = false;
        var forceOverride = (!subscriberData.ltkForceOverride) ? false : subscriberData.ltkForceOverride;
        try {
            _ltk.Subscriber.List = subscriber_code;
            for (var data in subscriberData) {
                var value = subscriberData[data];
                if ((!forceOverride && value == "") || data == "ltkSaved" || data == "ltkTrigger") continue;
                if (data == "ltkEmail" || data == "ltkUnsubscribe") _ltk.Subscriber.Email = value;
                else if (data == "ltkUpdatedEmail") _ltk.Subscriber.UpdatedEmail = value;
                else if (data.indexOf("ltkDate-") == 0) {
                    data = data.replace("ltkDate-", "");
                    _ltk.Subscriber.Profile.Add(data, getDate(value.month, value.day, value.year));
                }
                else _ltk.Subscriber.Profile.Add(data, value);
            }
            _ltk.Subscriber.Profile.Add("ltkSource", "on");

            if (Unsub) { _ltk_util.consoleLog('_ltk.Subscriber.Unsubscribe(true);'); _ltk.Subscriber.Unsubscribe(true); }
            else { _ltk_util.consoleLog('_ltk.Subscriber.Submit(true);'); _ltk.Subscriber.Submit(true); }
            wasSubmitted = true;
        } catch (ex) {
            _ltk.Exception.Submit(ex, 'SubmitSubscriber-' + subscriber_code);
        }
        if (wasSubmitted) deleteCookieSubscriberData(subscriber_code);
    }

    function SetSubscriberValue(subscriber_code, key, value, subKey) {
        var subscriberData = getCookieSubscriberData(subscriber_code);
        if (subKey) {
            if (!subscriberData[key]) subscriberData[key] = {};
            subscriberData[key][subKey] = value;
        } else {
            subscriberData[key] = value;
        }
        saveCookieSubscriberData(subscriber_code, subscriberData);
    }

    var CaptureSubscriberValue = new function () {
        function onchange(obj) {
            if (typeof obj == "undefined") return;
            var element = jQuery(this);
            var data = obj.data;
            var _list = data.list;
            var _id = data.id;
            var _options = data.options;
            var _key = _options.key;
            if (isGetRadioChecked(element, _options)) {
                var radios = element.length == 1 ? getElements(_id) : element;
                for (var i = 0; i < radios.length; i++) {
                    var radio = jQuery(radios[i]);
                    var _value = getElementValue(radio, _options);
                    var radioKey = _key + "-" + radio.val();
                    SetSubscriberValue(_list, radioKey, _value);
                }
            } else if (_options.date) {
                var _value = getElementValue(element, _options);
                SetSubscriberValue(_list, _key, _value, _options.date);
            } else {
                var _value = getElementValue(element, _options);
                SetSubscriberValue(_list, _key, _value);
            }
        }
        return function (subscriber_code, id, options) {
            if (typeof id == "undefined" || id == "") { return; }
            options = setDefaultOptions(id, options);
            try {
                _ltk_util.AsyncManager.StartAsyncCall('setupCaptureSubscriberValue-' + id, function () {
                    try {
                        var data = { list: subscriber_code, id: id, options: options };
                        var _sl = getElements(id);
                        if (_sl.length) {
                            if (_sl.change.length > 1) {
                                _sl.change(data, onchange);
                            } else {
                                _sl.bind("change", data, onchange);
                            }
                            onchange.apply(_sl, [{ data: data }]);
                        }
                    }
                    catch (ex) {
                        _ltk.Exception.Submit(ex, 'CaptureSubscriberValue-' + id);
                    }
                }, this, ['jQuery']);
            }
            catch (ex) {
                _ltk.Exception.Submit(ex, 'Init CaptureSubscriberValue-' + id);
            }
        };
    }

    if (document.dispatchEvent) {
        var event = new _ltk_util.CustomEvent("ltkSubscriberLoad", { detail: 'ltkSubscriberLoad' });
        document.dispatchEvent(event);
    }



    //////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////
    ///////  DEPRECATED CODE AFTER SIMPLIFCATIONS  ///////////
    //////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////

    _LTKSubscriber.prototype.SetEmail = function (subscriber_code, id) {
        _ltk_util.consoleLog('SetEmail function is deprecated. Please use SetSubPoint function.');
        setEmailWithTrigger(subscriber_code, id, "load");
    }

    _LTKSubscriber.prototype.SetEmailWithManualTrigger = function (subscriber_code, id) {
        _ltk_util.consoleLog('SetEmailWithManualTrigger function is deprecated. Please use SetSubPoint function.');
        setEmailWithTrigger(subscriber_code, id, "trigger");
    }

    _LTKSubscriber.prototype.SetEmailWithCheckoutTrigger = function (subscriber_code, id) {
        _ltk_util.consoleLog('SetEmailWithCheckoutTrigger function is deprecated. Please use SetSubPoint function.');
        setEmailWithTrigger(subscriber_code, id, "checkout");
        setSubmit(subscriber_code);
    }

    _LTKSubscriber.prototype.SetEmailWithButtonClick = function (subscriber_code, id, selector) {
        _ltk_util.consoleLog('SetEmailWithButtonClick function is deprecated. Please use SetSubPoint function.');
        setEmailWithTrigger(subscriber_code, id, "load");
        setButtonClick(subscriber_code, selector);
    }

    _LTKSubscriber.prototype.SetCheckoutEmailWithButtonClick = function (subscriber_code, id, selector) {
        _ltk_util.consoleLog('SetCheckoutEmailWithButtonClick function is deprecated. Please use SetSubPoint function.');
        setEmailWithTrigger(subscriber_code, id, "checkout");
        setButtonClick(subscriber_code, selector);
    }

    _LTKSubscriber.prototype.SetUnsubscribeEmail = function (subscriber_code, id) {
        _ltk_util.consoleLog('SetUnsubscribeEmail function is deprecated. Please use SetUnubPoint function.');
        setUnsubscribeEmailWithTrigger(subscriber_code, id, 'load');
    }

    _LTKSubscriber.prototype.SetUnsubscribeEmailWithManualTrigger = function (subscriber_code, id) {
        _ltk_util.consoleLog('SetUnsubscribeEmailWithManualTrigger function is deprecated. Please use SetUnubPoint function.');
        setUnsubscribeEmailWithTrigger(subscriber_code, id, 'trigger');
    }

    _LTKSubscriber.prototype.SetButtonClick = function (subscriber_code, selector) {
        _ltk_util.consoleLog('SetButtonClick function is deprecated. Please use SetSubPoint function with button click option.');
        setButtonClick(subscriber_code, selector);
    }

    /*function appendEvent(element, event, func) {
        if (!element) return;
        if (element.addEventListener) { element.addEventListener(event, func, false); }
        else if (element.attachEvent) { element.attachEvent("on" + event, func); }
        else if (jQuery.on) { element.on(event, func);}
        else if (jQuery.bind) {element.bind(event, func);}
        else _ltk.Exception.Submit("Cannot attach to event: " + event, 'SubscriberAppendEvent-' + event);
    }*/

    //////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////
    /////////////////  END DEPRECATIONS  ///////////////////
    //////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////




})();
