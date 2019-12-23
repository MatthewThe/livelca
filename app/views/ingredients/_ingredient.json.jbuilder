json.extract! ingredient, :id, :weight, :product_id, :recipe_id, :country_origin_id, :created_at, :updated_at
json.url ingredient_url(ingredient, format: :json)
