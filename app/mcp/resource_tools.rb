# Resources are publications (papers, reports, databases) that sources are taken from
module ResourceTools
  QUALITY_ATTRIBUTES = {
    peer_reviewed: Resource.peer_revieweds,
    num_products: Resource.num_products,
    meta_study: Resource.meta_studies,
    commissioned: Resource.commissioneds,
    year_of_study: Resource.year_of_studies,
    methodology_described: Resource.methodology_describeds,
    source_reputation: Resource.source_reputations,
  }
  ATTRIBUTES = [:name, :url, :notes] + QUALITY_ATTRIBUTES.keys
  # A new Resource holds its enum defaults as raw integers, which calculate_default_weight cannot look up
  QUALITY_DEFAULTS = QUALITY_ATTRIBUTES.to_h { |attr, values| [attr, values.key(Resource.new.public_send(attr)).to_s] }

  PROPERTIES = {
    name: { type: "string", description: "Title of the article, report or database, not its authors or DOI" },
    url: { type: "string", description: "Link to the resource, e.g. its DOI URL" },
    notes: { type: "string", description: "Markdown" },
  }.merge(QUALITY_ATTRIBUTES.transform_values { |values| { type: "string", enum: values.keys.map(&:to_s) } })

  def self.summary(resource)
    { id: resource.id, name: resource.name, url: resource.url, default_weight: resource.default_weight }
  end

  def self.details(resource)
    summary(resource)
      .merge(notes: resource.notes)
      .merge(QUALITY_ATTRIBUTES.keys.to_h { |attr| [attr, resource.public_send(attr)] })
      .merge(sources: resource.sources.with_associations(:product, :country_origin, :country_consumption).map { |s| SourceTools.details(s) })
  end

  ALL = [
    AdminTools.tool(
      name: "search_resources",
      description: "Find resources whose name contains the query (case-insensitive). For several names use match_names",
      properties: AdminTools::SEARCH_PROPERTIES,
      required: ["query"],
      read_only: true
    ) do |args, _user|
      AdminTools.search_by_name(Resource, args).map { |r| summary(r) }
    end,

    AdminTools.tool(
      name: "get_resource",
      description: "Get a resource with its quality ratings and all sources taken from it",
      properties: { id: { type: "string", description: "Resource UUID or URL slug" } },
      required: ["id"],
      read_only: true
    ) do |args, _user|
      details(Resource.find(Resource.from_param(args[:id])))
    end,

    AdminTools.tool(
      name: "create_resource",
      description: "Create a resource together with its sources (studies) in one call; its default source weight is derived " \
                   "from the quality ratings. Use dry_run first to show the user the resource, sources and resulting " \
                   "product CO2e changes, then end your turn; repeat the call without dry_run only after the user " \
                   "explicitly approved these entries in a later reply",
      properties: PROPERTIES.merge(
        sources: { type: "array", items: { type: "object", properties: SourceTools::PROPERTIES, required: ["product_name", "co2_equiv"] } }
      ),
      required: ["name"]
    ) do |args, _user|
      if Resource.where(name: /^#{Regexp.escape(args[:name])}$/i).exists?
        raise AdminTools::Error, "Resource \"#{args[:name]}\" already exists, add sources to it with create_source"
      end
      sources = args.fetch(:sources, [])
      AdminTools.check_names_exist!(
        Product => sources.map { |s| s[:product_name] },
        Country => sources.flat_map { |s| [s[:country_origin_name], s[:country_consumption_name]] }.select(&:present?)
      )

      products = sources.map { |s| s[:product_name] }.uniq.map { |name| Product.find_by(name: name) }
      co2_before = products.to_h { |p| [p.name, p.co2_equiv] }
      resource = AdminTools.save!(Resource.new(QUALITY_DEFAULTS.merge(args.slice(*ATTRIBUTES))))
      sources.each { |source_args| SourceTools.create(source_args, resource: resource) }
      co2_changes = products.map { |p| { product: p.name, co2_equiv_before: co2_before[p.name], co2_equiv_after: Product.find(p.id).co2_equiv } }
      details(resource).merge(product_co2_changes: co2_changes)
    end,

    AdminTools.tool(
      name: "update_resource",
      description: "Update a resource; only the given fields are changed. Sources still on the old default weight follow a changed default weight, and their products' CO2e is recomputed",
      properties: { id: { type: "string" } }.merge(PROPERTIES),
      required: ["id"]
    ) do |args, _user|
      resource = Resource.find(Resource.from_param(args[:id]))
      previous_default_weight = resource.default_weight
      resource.assign_attributes(args.slice(*ATTRIBUTES))
      AdminTools.save!(resource)
      # calculate_default_weight moves the sources with update_all, which skips their callbacks
      if resource.default_weight != previous_default_weight
        resource.sources.with_associations(:product).map(&:product).uniq.each(&:save)
      end
      details(resource)
    end,
  ]
end
