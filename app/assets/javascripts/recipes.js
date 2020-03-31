document.addEventListener("turbolinks:load", function() {
  "use strict";
  if ($("#ingredients_table_wrapper").length == 0) {
    $('#ingredients_table').DataTable({
      "paging": false,
      "order": [[ 0, "desc" ]]
    });
  }
  if ($("#recipes_table_wrapper").length == 0) {
    $('#recipes_table').DataTable({
      "pageLength": 25,
      "order": [[ 3, "desc" ]]
    });
  }
})
