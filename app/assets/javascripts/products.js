document.addEventListener("turbolinks:load", function() {
  "use strict";
  if ($("#products_table_wrapper").length == 0) {
    $('#products_table').DataTable({
      "pageLength": 25
    });
  }
})
