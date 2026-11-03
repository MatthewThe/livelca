module RecipeTools
  ATTRIBUTES = [:name, :servings, :description, :instructions, :url, :is_public]

  PROPERTIES = {
    name: { type: "string" },
    servings: { type: "number" },
    description: { type: "string" },
    instructions: { type: "string", description: "One step per line" },
    url: { type: "string", description: "Original recipe URL" },
    is_public: { type: "boolean" },
    country_consumption_name: { type: "string", description: "Name of an existing country, defaults to Unknown" },
    tags: { type: "array", items: { type: "string" }, description: "Names of existing tags; replaces all tags" },
  }

  def self.summary(recipe)
    { id: recipe.id, name: recipe.name, servings: recipe.servings, co2_equiv: recipe.co2_equiv, is_public: recipe.is_public }
  end

  def self.details(recipe)
    summary(recipe).merge(
      co2_equiv_per_serving: recipe.co2_equiv_per_serving,
      description: recipe.description,
      instructions: recipe.instructions,
      url: recipe.url,
      country_consumption: recipe.country_consumption&.name,
      owner: recipe.user&.email,
      tags: recipe.tags.map(&:name),
      ingredients: recipe.ingredients.with_associations(:product, :country_origin).map { |i| IngredientTools.details(i) }
    )
  end

  def self.assign_relations(recipe, args)
    recipe.country_consumption = AdminTools.find_country(args[:country_consumption_name]) if args.key?(:country_consumption_name)
    recipe.tags = args[:tags].map { |name| AdminTools.find_by_name!(Tag, name) } if args.key?(:tags)
  end

  ALL = [
    AdminTools.tool(
      name: "search_recipes",
      description: "Find recipes (public and private) whose name contains the query (case-insensitive)",
      properties: AdminTools::SEARCH_PROPERTIES,
      required: ["query"],
      read_only: true
    ) do |args, _user|
      AdminTools.search_by_name(Recipe, args).map { |r| summary(r) }
    end,

    AdminTools.tool(
      name: "get_recipe",
      description: "Get a recipe with its ingredients, tags and CO2e",
      properties: { id: { type: "string", description: "Recipe UUID or URL slug" } },
      required: ["id"],
      read_only: true
    ) do |args, _user|
      details(Recipe.find(Recipe.from_param(args[:id])))
    end,

    AdminTools.tool(
      name: "create_recipe",
      description: "Create a recipe owned by the calling admin, optionally with ingredients",
      properties: PROPERTIES.merge(
        ingredients: { type: "array", items: { type: "object", properties: IngredientTools::PROPERTIES, required: ["product_name", "weight"] } }
      ),
      required: ["name", "servings"]
    ) do |args, user|
      recipe = Recipe.new(args.slice(*ATTRIBUTES))
      recipe.user = user
      assign_relations(recipe, { country_consumption_name: "" }.merge(args))
      args.fetch(:ingredients, []).each do |ingredient_args|
        ingredient = Ingredient.new(ingredient_args.slice(*IngredientTools::ATTRIBUTES))
        IngredientTools.assign_relations(ingredient, { country_origin_name: "" }.merge(ingredient_args))
        recipe.ingredients << ingredient
      end
      details(AdminTools.save!(recipe))
    end,

    AdminTools.tool(
      name: "update_recipe",
      description: "Update a recipe's fields; only the given fields are changed. Use the ingredient tools to change ingredients",
      properties: { id: { type: "string" } }.merge(PROPERTIES),
      required: ["id"]
    ) do |args, _user|
      recipe = Recipe.find(Recipe.from_param(args[:id]))
      assign_relations(recipe, args)
      recipe.assign_attributes(args.slice(*ATTRIBUTES))
      details(AdminTools.save!(recipe))
    end,
  ]
end
