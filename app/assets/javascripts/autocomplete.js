document.addEventListener("turbolinks:load", function() {
  $("#country-origin-autocomplete").autocomplete({
    source: '/country_autocomplete',
    autoFocus: true,
  })

  $("#country-consumption-autocomplete").autocomplete({
    source: '/country_autocomplete',
    autoFocus: true,
  })
  
  $("#product-autocomplete").autocomplete({
    source: '/product_autocomplete',
    autoFocus: true,
  })

  $("#product-autocomplete-2").autocomplete({
    source: '/product_autocomplete',
    autoFocus: true,
  })
})
