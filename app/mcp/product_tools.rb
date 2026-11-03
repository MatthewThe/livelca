module ProductTools
  def self.summary(product)
    { id: product.id, name: product.name, co2_equiv: product.co2_equiv, category: product.category_name }
  end

  def self.details(product)
    summary(product).merge(
      wiki: product.wiki,
      proxy: product.proxy_name,
      reliability: product.reliability_class,
      subcategories: product.subcategories.map(&:name).sort,
      aliases: product.aliases.map { |a| { name: a.name, redirect: a.redirect } },
      studies: product.studies.with_associations(:resource, :country_origin, :country_consumption).map { |s| SourceTools.details(s) }
    )
  end

  # Empty names clear the relation, missing keys leave it untouched
  def self.assign_relations(product, args)
    if args.key?(:category_name)
      product.category = args[:category_name].presence && AdminTools.find_by_name!(Product, args[:category_name])
    end
    if args.key?(:proxy_name)
      product.proxy = args[:proxy_name].presence && AdminTools.find_by_name!(Product, args[:proxy_name])
    end
  end

  # Products are referenced by name throughout the app, so names must stay unique
  def self.check_name_available(name, product = nil)
    existing = Product.find_by(name: name)
    raise AdminTools::Error, "Product \"#{name}\" already exists" if existing && existing != product
  end

  RELATION_PROPERTIES = {
    category_name: { type: "string", description: "Name of an existing parent product; empty string removes it" },
    proxy_name: { type: "string", description: "Name of an existing product whose CO2e is used when there are no studies; empty string removes it" },
  }

  ALL = [
    AdminTools.tool(
      name: "search_products",
      description: "Find products whose name starts with the query (case-insensitive), including redirect aliases. For several names use match_names",
      properties: AdminTools::SEARCH_PROPERTIES,
      required: ["query"],
      read_only: true
    ) do |args, _user|
      limit = args.fetch(:limit, 25)
      products = Product.search(args[:query]).limit(limit).with_associations(:category).map { |p| summary(p) }
      aliases = ProductAlias.search_redirects(args[:query]).first(limit).map { |a| { alias: a.name, product: summary(a.product) } }
      { products: products, redirect_aliases: aliases }
    end,

    AdminTools.tool(
      name: "get_product",
      description: "Get a product with its wiki, category, proxy, subcategories, aliases and studies",
      properties: { id: { type: "string", description: "Product UUID or URL slug" } },
      required: ["id"],
      read_only: true
    ) do |args, _user|
      details(Product.find(Product.from_param(args[:id])))
    end,

    AdminTools.tool(
      name: "create_product",
      description: "Create a product",
      properties: { name: { type: "string" }, wiki: { type: "string", description: "Markdown" } }.merge(RELATION_PROPERTIES),
      required: ["name"]
    ) do |args, _user|
      check_name_available(args[:name])
      product = Product.new(args.slice(:name, :wiki))
      assign_relations(product, args)
      details(AdminTools.save!(product))
    end,

    AdminTools.tool(
      name: "update_product",
      description: "Update a product; only the given fields are changed",
      properties: { id: { type: "string" }, name: { type: "string" }, wiki: { type: "string", description: "Markdown" } }.merge(RELATION_PROPERTIES),
      required: ["id"]
    ) do |args, _user|
      product = Product.find(Product.from_param(args[:id]))
      check_name_available(args[:name], product) if args.key?(:name)
      assign_relations(product, args)
      product.assign_attributes(args.slice(:name, :wiki))
      details(AdminTools.save!(product))
    end,
  ]
end
