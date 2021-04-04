window.addEventListener('load', function() {
  setChartMetricListener();
})

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
        document.querySelector('.highcharts-yaxis tspan').innerHTML = metricTitle + (metricUnit ? ' ('+metricUnit+')' : '');
      }, { metric: selectedMetric.value });
    })
  }
}

function getChartData(callback, options) {
  options = options || {};
  var metric = options.metric || 'psi';
  var xhr = new XMLHttpRequest();
  xhr.open('GET', '/charts/domain/'+window.currentDomainId+'?metric_type='+metric+'&tag_ids='+window.scriptSubscribersIds, true);
  xhr.send();
  xhr.onreadystatechange = function() {
    if (xhr.readyState == XMLHttpRequest.DONE) {
      var response = JSON.parse(xhr.responseText);
      callback(response);
    }
  }
}


// function renderChart() {
//   getChartData(function(chartData) {
//     const epochStartDate = Math.min.apply(Math, chartData.map(function(data) { return Date.parse(Object.keys(data.data)[0]); }));
//     const epochEndDate = Math.max.apply(Math, chartData.map(function(data) { var timestamps = Object.keys(data.data); return Date.parse(timestamps[timestamps.length-1]); }));
//     return Highcharts.chart('scripts-chart-container', {
//       chart: {
//         type: 'line'
//       },
//       title: {
//         text: 'Performance Score Impact'
//       },
//       yAxis: {
//         title: {
//           text: 'Performance Score Impact'
//         }
//       },
//       xAxis: { 
//         type: 'datetime',
//         title: {
//           text: 'Tag Changes'
//         }
//       },
//       plotOptions: {
//         series: {
//             pointStart: epochStartDate,
//             pointEnd: epochEndDate
//             // pointInterval: 86400 * 1000
//         }
//       },
//       series: formatChartData(chartData)
//     });
//   });
// }

// function formatChartData(chartData) {
//   var formatted = chartData.map(function(data) {
//     // reverse order here because data.data is an object of datetime: score in order
//     // from oldest to most recent, parsing to array flips order in opposite direction
//     let dataObjectAsArray = Object.keys(data.data).reverse(); 
//     return {
//       name: data.name,
//       data: dataObjectAsArray.map(function(timestamp) { return [timestamp, data.data[timestamp]] })
//     }
//   });
//   return formatted
// }
