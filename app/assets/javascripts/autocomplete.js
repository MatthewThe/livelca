document.addEventListener("turbolinks:load", function() {
  $("#country-origin-autocomplete").autocomplete({
    source: '/country_autocomplete',
  })

  $("#country-consumption-autocomplete").autocomplete({
    source: '/country_autocomplete',
  })
  
  $("#product-autocomplete").autocomplete({
    source: '/product_autocomplete',
  })

  $("#product-autocomplete-2").autocomplete({
    source: '/product_autocomplete',
  })
})
