json.extract! recipe, :id, :name, :servings, :user_id, :ingredients_id, :created_at, :updated_at
json.url recipe_url(recipe, format: :json)
