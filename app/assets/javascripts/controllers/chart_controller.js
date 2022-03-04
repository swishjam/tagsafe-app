import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['datepicker'];

  connect() {
    this._initializeDatepicker();
  }

  _initializeDatepicker() {
    $(this.datepickerTarget).daterangepicker({
      timePicker: true,
      startDate: moment(this.datepickerTarget.getAttribute('data-start')),
      endDate: moment(this.datepickerTarget.getAttribute('data-end')),
      locale: {
        format: 'M/DD hh:mm A zz'
      },
      // applyButtonClasses: '',
      // cancelButtonClasses: '',
    }, (start, end, _label) => this._onDateRangeChange(start, end) );
  }

  _onDateRangeChange(start, end) {
    let turboframe = this.element.closest('turbo-frame');
    let src = new URL(window.location.origin + this.element.getAttribute('data-fetch-url'));
    src.searchParams.set('start_time', start.toISOString());
    src.searchParams.set('end_time', end.toISOString());
    // we're able to set the src attribute even though we are sending turbo stream updates 
    // to the turbo frame and therefore is not lazily loaded
    turboframe.setAttribute('src', src.pathname + src.search)
  }
}