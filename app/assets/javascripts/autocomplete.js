document.addEventListener("turbolinks:load", function() {
  $('[id^="country-autocomplete"').autocomplete({
    source: '/country_autocomplete',
    autoFocus: true,
  })
  
  $('[id^="product-autocomplete"]').autocomplete({
    source: '/product_autocomplete',
    autoFocus: true,
  })
})
