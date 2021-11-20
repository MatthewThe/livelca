$( document ).ready(function() {
  "use strict";
  if ($("#resources_table_wrapper").length == 0) {
    $('#resources_table').DataTable({
      "pageLength": 25,
      "stateSave": true,
      "deferRender": true,
      "oLanguage": {
         "sSearch": "Filter:"
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
  initSourcesTable();
})

function initSourcesTable() {
  if ($("#sources_product_table_wrapper").length == 0) {
    $('#sources_product_table').DataTable({
      "pageLength": 25
    });
  }
}
