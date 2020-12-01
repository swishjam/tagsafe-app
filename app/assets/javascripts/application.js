// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require_tree .
//= require chartkick
//= require highcharts
//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require bootstrap-select

window.addEventListener('load', function() {
  // let chart = renderChart();
  setChartMetricListener();

  setScriptSubscriberToggleListeners();
  setScriptSubscriberChartMetricListener();

  $('[data-toggle="tooltip"]').tooltip();
  $('.selectpicker').selectpicker();
  $('.toast').toast({ 
    animation: false,
    delay: 12000
  });
  $('.toast:not(.js-toast)').toast('show');
});

function renderChart() {
  getChartData(function(chartData) {
    const epochStartDate = Math.min.apply(Math, chartData.map(function(data) { return Date.parse(Object.keys(data.data)[0]); }));
    const epochEndDate = Math.max.apply(Math, chartData.map(function(data) { var timestamps = Object.keys(data.data); return Date.parse(timestamps[timestamps.length-1]); }));
    return Highcharts.chart('scripts-chart-container', {
      chart: {
        type: 'line'
      },
      title: {
        text: 'Performance Score Impact'
      },
      yAxis: {
        title: {
          text: 'Performance Score Impact'
        }
      },
      xAxis: { 
        type: 'datetime',
        title: {
          text: 'Tag Changes'
        }
      },
      plotOptions: {
        series: {
            pointStart: epochStartDate,
            pointEnd: epochEndDate
            // pointInterval: 86400 * 1000
        }
      },
      series: formatChartData(chartData)
    });
  });
}

function formatChartData(chartData) {
  var formatted = chartData.map(function(data) {
    // reverse order here because data.data is an object of datetime: score in order
    // from oldest to most recent, parsing to array flips order in opposite direction
    let dataObjectAsArray = Object.keys(data.data).reverse(); 
    return {
      name: data.name,
      data: dataObjectAsArray.map(function(timestamp) { return [timestamp, data.data[timestamp]] })
    }
  });
  return formatted
}

function setChartMetricListener() {
  var dropdown = document.querySelector('#metric-dropdown');
  var chart = Chartkick.charts['chart-1'];
  if(dropdown) {
    dropdown.addEventListener('change', function(e) {
      var selectedMetric = e.currentTarget.selectedOptions[0];
      var metricUnit = selectedMetric.getAttribute('data-metric-unit');
      var metricTitle = selectedMetric.innerText;
      getChartData(function(chartData) {
        chart.updateData(chartData);
        document.querySelector('.highcharts-title tspan').innerHTML = metricTitle+' Impact Over Time';
        document.querySelector('.highcharts-yaxis tspan').innerHTML = metricTitle +' ('+metricUnit+')';
      }, { metric: selectedMetric.value });
    })
  }
}

function getChartData(callback, options) {
  options = options || {};
  var metric = options.metric || 'psi';
  var xhr = new XMLHttpRequest();
  xhr.open('GET', '/charts/domain/'+window.currentDomainId+'?metric='+metric+'&script_subscriber_ids='+window.scriptSubscribersIds, true);
  xhr.send();
  xhr.onreadystatechange = function() {
    if (xhr.readyState == XMLHttpRequest.DONE) {
      var response = JSON.parse(xhr.responseText);
      callback(response);
    }
  }
}

function setScriptSubscriberChartMetricListener() {
  var chart = Chartkick.charts["chart-1"];
  $('#chart-metrics-dropdown').on('hide.bs.select', function(event) {
    var metricKeys = [];
    var selectedMetrics = event.currentTarget.selectedOptions;
    for(i=0; i<selectedMetrics.length; i++) {
      metricKeys.push(selectedMetrics[i].value);
    }
    if(metricKeys.length === 0) metricKeys.push('psi');
    var xhr = new XMLHttpRequest();
    xhr.open('GET', '/charts/script_subscriber/'+window.scriptSubscriberId+'?metric_keys='+JSON.stringify(metricKeys), true);
    xhr.send();
    xhr.onreadystatechange = function() {
      if (xhr.readyState == XMLHttpRequest.DONE) {
        var response = JSON.parse(xhr.responseText);
        chart.updateData(response);
        // document.querySelector('.highcharts-title tspan').innerHTML = selectedMetric.innerText+' Impact Over Time';
        // document.querySelector('.highcharts-yaxis tspan').innerHTML = selectedMetric.innerText
      }
    }
  })
}

function setScriptSubscriberToggleListeners() {
  var scriptToggles = document.querySelectorAll('.script-subscriber-active-toggle');
  for(i=0; i<scriptToggles.length; i++) {
    var toggle = scriptToggles[i];
    toggle.addEventListener('click', function(e) {
      var scriptSubscriberId = e.currentTarget.getAttribute('data-script-subscriber');
      if(scriptSubscriberId) {
        var xhr = new XMLHttpRequest();
        xhr.open('POST', '/api/script_subscribers/'+scriptSubscriberId+'/toggle_active', true);
        xhr.send();
        xhr.onreadystatechange = function() {
          if (xhr.readyState == XMLHttpRequest.DONE) {
            var response = JSON.parse(xhr.responseText);
            showToastMessage(response.message);
          }
        }
      }
    })
  }
}

function showToastMessage(msg) {
  $('.js-toast .toast-body').text(msg);
  $('.js-toast').toast('show');
}