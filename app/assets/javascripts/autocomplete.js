$( document ).ready(function() {
  $('[id^="country-autocomplete"]').autocomplete({
    source: '/country_autocomplete',
    autoFocus: true,
  })
  
  $('[id^="product-autocomplete"]').autocomplete({
    source: '/product_autocomplete_name',
    autoFocus: true
  })
  
  $('[id^="product-select-autocomplete"]').autocomplete({
    source: '/product_autocomplete',
    focus: function( event, ui ) { this.value = ui.item.label; return false; },
    select: function( event, ui ) { this.value = ui.item.label; window.location.href = "/products/" + ui.item.value; return false; }
  })
})
