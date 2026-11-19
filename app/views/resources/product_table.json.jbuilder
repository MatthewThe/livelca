is_admin = user_signed_in? && current_user.admin?

json.draw @draw
json.recordsTotal @records_total
json.recordsFiltered @records_filtered
json.data @rows do |source, product, origin, consumption|
  product_cell = product ? link_to(product.name, product) : ""
  if is_admin
    admin_links = link_to(image_tag("modify.png", size: "12x12", alt: "Edit"), edit_source_path(source)) + " " +
      link_to(image_tag("erase.png", size: "12x12", alt: "Delete"), source, method: :delete, data: { confirm: 'Are you sure?' })
    product_cell = admin_links + " " + product_cell
  end

  json.array! [
    product_cell.to_s,
    source.notes.to_s.gsub(/[\r\n]+/, '<br>'),
    h(origin),
    h(consumption)
  ]
end
