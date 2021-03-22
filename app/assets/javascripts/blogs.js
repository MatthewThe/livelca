var updateWiki;

$( document ).ready(function() {
  "use strict";
   if ($("#blogs_table_wrapper").length == 0) {
    $('#blogs_table').DataTable({
      "pageLength": 25,
      "order": [[ 1, "desc" ]],
      "stateSave": true,
      "deferRender": true,
      "oLanguage": {
         "sSearch": "Filter:"
      },
      "ajax": {
        "url":'/blog_table.json',
        "cache": true,
      },
      "language": {
         "loadingRecords": "Please wait - loading blogs..."
      },
      "columnDefs": [
        { "width": "250px", "targets": 0 },
        { "width": "80px", "targets": 1 }
      ]
    });
  }
  
  if ($("#editor").length > 0) {
    const editor = new toastui.Editor({
      el: document.querySelector('#editor'),
      height: '500px',
      initialEditType: 'markdown',
      previewStyle: 'vertical',
      usageStatistics: false
    });
    
    $('#wiki-editor').hide();
    editor.setMarkdown($('#wiki-editor').val())
    updateWiki = function() {
      $('#wiki-editor').val(editor.getMarkdown());
    }
  }
})
