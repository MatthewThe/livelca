$( document ).ready(function() {
  "use strict";
  if ($("#resources_table_wrapper").length == 0) {
    $('#resources_table').DataTable({
      "pageLength": 10,
      "stateSave": true,
      "deferRender": true,
      "oLanguage": {
         "search": "Search:"
      },
      "bLengthChange" : false,
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
      "pageLength": 25,
      "responsive": true,
      "oLanguage": {
         "sSearch": "Filter:"
      },
      "ajax": {
        "url":'/resource_product_table.json',
        "data": function ( d ) {
            d.id = window.location.pathname.split("/").pop();
        }
      },
      "language": {
         "loadingRecords": "Please wait - loading products..."
      },
      "columnDefs": [
        { "targets": 1, "className" : "none" }
      ]
    });
  }
}
