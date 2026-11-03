module IngredientTools
  ATTRIBUTES = [:weight, :description]

  PROPERTIES = {
    product_name: { type: "string", description: "Name of an existing product" },
    weight: { type: "number", description: "kg" },
    description: { type: "string", description: "Original ingredient line, e.g. \"2 large potatoes\"" },
    country_origin_name: { type: "string", description: "Name of an existing country, defaults to Unknown" },
  }

  def self.details(ingredient)
    {
      id: ingredient.id,
      product: ingredient.product_name,
      weight: ingredient.weight,
      description: ingredient.description,
      country_origin: ingredient.country_origin_name,
      co2_equiv: ingredient.product && ingredient.co2_equiv,
    }
  end

  def self.assign_relations(ingredient, args)
    ingredient.product = AdminTools.find_by_name!(Product, args[:product_name]) if args.key?(:product_name)
    ingredient.country_origin = AdminTools.find_country(args[:country_origin_name]) if args.key?(:country_origin_name)
  end

  ALL = [
    AdminTools.tool(
      name: "add_ingredient",
      description: "Add an ingredient to a recipe; recomputes the recipe's CO2e",
      properties: { recipe_id: { type: "string", description: "Recipe UUID or URL slug" } }.merge(PROPERTIES),
      required: ["recipe_id", "product_name", "weight"]
    ) do |args, _user|
      recipe = Recipe.find(Recipe.from_param(args[:recipe_id]))
      ingredient = Ingredient.new(args.slice(*ATTRIBUTES))
      assign_relations(ingredient, { country_origin_name: "" }.merge(args))
      AdminTools.save!(ingredient)
      recipe.ingredients << ingredient
      AdminTools.save!(recipe)
      RecipeTools.details(recipe)
    end,

    AdminTools.tool(
      name: "update_ingredient",
      description: "Update an ingredient; only the given fields are changed. Recomputes the recipe's CO2e",
      properties: { id: { type: "string" } }.merge(PROPERTIES),
      required: ["id"]
    ) do |args, _user|
      ingredient = Ingredient.find(args[:id])
      assign_relations(ingredient, args)
      ingredient.assign_attributes(args.slice(*ATTRIBUTES))
      AdminTools.save!(ingredient)
      recipe = ingredient.recipe
      AdminTools.save!(recipe)
      RecipeTools.details(recipe)
    end,

    AdminTools.tool(
      name: "remove_ingredient",
      description: "Remove an ingredient from its recipe; recomputes the recipe's CO2e",
      properties: { id: { type: "string" } },
      required: ["id"],
      destructive: true
    ) do |args, _user|
      ingredient = Ingredient.find(args[:id])
      recipe = ingredient.recipe
      ingredient.destroy
      AdminTools.save!(recipe)
      RecipeTools.details(recipe)
    end,
  ]
end
