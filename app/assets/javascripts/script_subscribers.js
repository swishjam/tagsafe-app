window.addEventListener('load', function() {
  var stateKeeper = {
    metricKeys: ['DOMComplete'],
    chartType: 'impact'
  }
  setScriptSubscriberToggleListeners();
  setScriptSubscriberChartMetricListener(stateKeeper);
  setScriptSubscriberChartTypeToggleListener(stateKeeper);
});

function setScriptSubscriberChartTypeToggleListener(stateKeeper) {
  $('input[name="chart-type"]').on('change', function(e) {
    var chartType = e.currentTarget.value;
    stateKeeper.chartType = chartType;
    updateChartData(chartType, stateKeeper.metricKeys)
  })
}

function setScriptSubscriberChartMetricListener(stateKeeper) {
  $('#chart-metrics-dropdown').on('hide.bs.select', function(event) {
    var metricKeys = [];
    var selectedMetrics = event.currentTarget.selectedOptions;
    for(i=0; i<selectedMetrics.length; i++) {
      metricKeys.push(selectedMetrics[i].value);
    }
    if(metricKeys.length === 0) metricKeys.push('DOMComplete');
    stateKeeper.metricKeys = metricKeys;
    updateChartData(stateKeeper.chartType, stateKeeper.metricKeys);
  })
}

function updateChartData(chartType, metricKeys) {
  var chart = Chartkick.charts["chart-1"];
  var xhr = new XMLHttpRequest();
    xhr.open('GET', `/charts/script_subscriber/${window.scriptSubscriberId}?chart_type=${chartType}&metric_keys=${JSON.stringify(metricKeys)}`, true);
    xhr.send();
    xhr.onreadystatechange = function() {
      if (xhr.readyState == XMLHttpRequest.DONE) {
        var response = JSON.parse(xhr.responseText);
        chart.updateData(response);
        // document.querySelector('.highcharts-title tspan').innerHTML = selectedMetric.innerText+' Impact Over Time';
        // document.querySelector('.highcharts-yaxis tspan').innerHTML = selectedMetric.innerText
      }
    }
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
          if(xhr.readyState == XMLHttpRequest.DONE) {
            var response = JSON.parse(xhr.responseText);
            showToastMessage(response.message);
          }
        }
      }
    })
  }
}