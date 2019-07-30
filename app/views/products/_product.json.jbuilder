json.extract! product, :id, :name, :wiki, :created_at, :updated_at
json.url product_url(product, format: :json)
