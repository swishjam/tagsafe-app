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
//= require jquery
//= require jquery_ujs
//= require activestorage
//= require_tree .
//= require chartkick
//= require highcharts
//= require popper
//= require bootstrap-sprockets

window.addEventListener('load', function() {
  $('[data-toggle="tooltip"]').tooltip();
  $('.selectpicker').selectpicker();
  $('.toast').toast({ 
    animation: false,
    delay: 12000
  });
  $('.toast:not(.js-toast)').toast('show');
  $('.custom-file-input').on('change',function(){
    //get the file name
    var fileName = $(this).val();
    //replace the "Choose a file" label
    $(this).next('.custom-file-label').html(fileName);
  })
});

function showToastMessage(msg) {
  $('.js-toast .toast-body').text(msg);
  $('.js-toast').toast('show');
}