$( document ).ready(function() {
  "use strict";
  initTagsTable();
})

function initTagsTable() {
  if ($("#tags_table_wrapper").length == 0) {
    $('#tags_table').DataTable({
      "order": [[ 3, "desc" ]],
      "paging": true,
      "searching": true,
      "responsive": true
    });
  }
}
