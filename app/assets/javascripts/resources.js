document.addEventListener("turbolinks:load", function() {
  "use strict";
  if ($("#resources_table_wrapper").length == 0) {
    $('#resources_table').DataTable({
      "pageLength": 25,
      "stateSave": true,
      "deferRender": true,
      "oLanguage": {
         "sSearch": "Filter resources:"
      },
      "ajax": {
        "url":'/resource_table.json',
        "cache": true,
      },
      "language": {
         "loadingRecords": "Please wait - loading resources..."
      },
    });
  }
  if ($("#sources_table_wrapper").length == 0) {
    $('#sources_table').DataTable({
      "pageLength": 25
    });
  }
})
