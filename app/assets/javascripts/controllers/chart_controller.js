import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['datepicker'];

  connect() {
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
    let src = new URL(window.location.origin + turboframe.getAttribute('src'));
    src.searchParams.set('start_time', start.toISOString());
    src.searchParams.set('end_time', end.toISOString());
    turboframe.setAttribute('src', src.pathname + src.search)
  }
}