import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [
    'totalCredits', 'performanceAuditCheckbox', 'functionalTestsCheckbox', 'resourceWaterfallCheckbox',
    'screenRecordingCheckbox', 'filmstripCheckbox', 'urlToAuditCheckbox'
  ];
  static values = {
    manualPerformanceAuditCredits: Number,
    manualFunctionalTestCredits: Number,
    numFunctionalTests: Number,
    resourceWaterfallCredits: Number,
    screenRecordingCredits: Number,
    filmstripCredits: Number
  }

  connect() {
    this._calculateAuditPrice();
    this._listenForChanges();
  }

  _listenForChanges() {
    this.performanceAuditCheckboxTarget.addEventListener('change', () => this._calculateAuditPrice())
    this.functionalTestsCheckboxTarget.addEventListener('change', () => this._calculateAuditPrice())
    this.resourceWaterfallCheckboxTarget.addEventListener('change', () => this._calculateAuditPrice())
    this.screenRecordingCheckboxTarget.addEventListener('change', () => this._calculateAuditPrice())
    this.filmstripCheckboxTarget.addEventListener('change', () => this._calculateAuditPrice())
    this.urlToAuditCheckboxTargets.forEach(urlToAuditCheckbox => urlToAuditCheckbox.addEventListener('change', () => this._calculateAuditPrice() ));
  }

  _calculateAuditPrice() {
    const costPerUrl = this._manualPerformanceAuditPrice() + 
                        this._functionalTestsPrice() + 
                        this._resourceWaterfallPrice() + 
                        this._screenRecordingPrice() + 
                        this._filmstripPrice();
    const totalPrice = costPerUrl * this._numUrlsToAudit();
    this.totalCreditsTarget.innerText =  `${totalPrice} credits`;
  }

  _manualPerformanceAuditPrice() {
    return this.performanceAuditCheckboxTarget.checked ? this.manualPerformanceAuditCreditsValue : 0
  }

  _resourceWaterfallPrice() {
    return this.resourceWaterfallCheckboxTarget.checked && this._manualPerformanceAuditPrice() > 0 ? this.resourceWaterfallCreditsValue : 0
  }

  _screenRecordingPrice() {
    return this.screenRecordingCheckboxTarget.checked && this._manualPerformanceAuditPrice() > 0 ? this.screenRecordingCreditsValue : 0
  }

  _filmstripPrice() {
    return this.filmstripCheckboxTarget.checked && this._manualPerformanceAuditPrice() > 0 ? this.filmstripCreditsValue : 0
  }

  _functionalTestsPrice() {
    return (this.functionalTestsCheckboxTarget.checked ? this.manualFunctionalTestCreditsValue : 0) * this.numFunctionalTestsValue
  }

  _numUrlsToAudit() {
    let sum = 0;
    this.urlToAuditCheckboxTargets.forEach(checkbox => { if(checkbox.checked) sum += 1 });
    return sum;
  }
}