window.addEventListener('load', function() {
  var minimizeDetailsButton = document.querySelector('.minimize-audit-details');
  if(minimizeDetailsButton) {
    var expandDetailsButton = document.querySelector('.expand-audit-details');
    var metricsContainer = document.querySelector('.performance-metrics-container');
    minimizeDetailsButton.addEventListener('click', function() {
      if(minimizeDetailsButton.className.indexOf('selected') === -1) {
        minimizeDetailsButton.className += ' selected';
        expandDetailsButton.className = 'expand-audit-details';
        metricsContainer.className += ' minimized';
      }
    })
    expandDetailsButton.addEventListener('click', function() {
      if(expandDetailsButton.className.indexOf('selected') === -1) {
        expandDetailsButton.className += ' selected';
        minimizeDetailsButton.className = 'minimize-audit-details';
        metricsContainer.className = 'performance-metrics-container';
      }
    })
  }
})