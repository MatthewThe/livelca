document.addEventListener("turbolinks:load", function() {
  "use strict";
  if ($("#resources_table_wrapper").length == 0) {
    $('#resources_table').DataTable({
      "pageLength": 25
    });
  }
  if ($("#sources_table_wrapper").length == 0) {
    $('#sources_table').DataTable({
      "pageLength": 25
    });
  }
})
