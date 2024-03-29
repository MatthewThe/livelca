// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require d3
//= require lodash
//= require_tree .
//= require jquery-ui/widgets/autocomplete
//= require jquery-ui/widgets/tooltip
//= require jquery.dataTables.min
//= require chosen-jquery
//= require blocks
//= require plates
//= require html2pdf.bundle.min


$(document).on('click', 'a[data-remote=true]', function(e) {
  history.pushState({}, '', $(this).attr('href'));
});

$(window).on('popstate', function () {
  $.get(document.location.href)
});

jQuery.loadCSS = function(url) {
    if (!$('link[href="' + url + '"]').length)
        $('head').append('<link rel="stylesheet" type="text/css" href="' + url + '">');
}

$(document).ajaxStart(function() {
  $("#loading_animation").height($(document).height());
  $("#loading_animation").addClass("show");
}).ajaxStop(function() {
  $("#loading_animation").removeClass("show");
});
