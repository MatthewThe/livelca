# Sources are the individual studies (CO2e data points) of a product, grouped by resource
module SourceTools
  def self.details(source)
    {
      id: source.id,
      product: source.product_name,
      resource: source.resource && { id: source.resource.id, name: source.resource.name },
      co2_equiv: source.co2_equiv,
      co2_emission: source.co2_emission,
      ch4_emission: source.ch4_emission,
      n2o_emission: source.n2o_emission,
      weight: source.weight,
      notes: source.notes,
      country_origin: source.country_origin_name,
      country_consumption: source.country_consumption_name,
    }
  end

  def self.assign_relations(source, args)
    source.product = AdminTools.find_by_name!(Product, args[:product_name]) if args.key?(:product_name)
    source.resource = Resource.find(Resource.from_param(args[:resource_id])) if args.key?(:resource_id)
    source.country_origin = AdminTools.find_country(args[:country_origin_name]) if args.key?(:country_origin_name)
    source.country_consumption = AdminTools.find_country(args[:country_consumption_name]) if args.key?(:country_consumption_name)
  end

  ATTRIBUTES = [:co2_equiv, :co2_emission, :ch4_emission, :n2o_emission, :weight, :notes]

  PROPERTIES = {
    product_name: { type: "string", description: "Name of an existing product" },
    resource_id: { type: "string", description: "UUID or URL slug of an existing resource" },
    co2_equiv: { type: "number", description: "kg CO2e per kg of product" },
    co2_emission: { type: "number" },
    ch4_emission: { type: "number" },
    n2o_emission: { type: "number" },
    weight: { type: "integer", description: "Weight in the product's CO2e average; defaults to the resource's default weight, 0 excludes the study" },
    notes: { type: "string" },
    country_origin_name: { type: "string", description: "Name of an existing country, defaults to Unknown" },
    country_consumption_name: { type: "string", description: "Name of an existing country, defaults to Unknown" },
  }

  ALL = [
    AdminTools.tool(
      name: "create_source",
      description: "Add a study (CO2e data point) for a product from a resource; recomputes the product's CO2e",
      properties: PROPERTIES,
      required: ["product_name", "resource_id", "co2_equiv"]
    ) do |args, _user|
      source = Source.new(args.slice(*ATTRIBUTES))
      assign_relations(source, { country_origin_name: "", country_consumption_name: "" }.merge(args))
      source.weight = source.resource.default_weight unless args.key?(:weight)
      AdminTools.save!(source)
      source.product.save # after_save ran before the new study was linked to the product
      details(source)
    end,

    AdminTools.tool(
      name: "update_source",
      description: "Update a study; only the given fields are changed. Recomputes the product's CO2e",
      properties: { id: { type: "string" } }.merge(PROPERTIES),
      required: ["id"]
    ) do |args, _user|
      source = Source.find(args[:id])
      previous_product = source.product
      assign_relations(source, args)
      source.assign_attributes(args.slice(*ATTRIBUTES))
      AdminTools.save!(source)
      previous_product.save if previous_product != source.product # recompute without the moved study
      details(source)
    end,
  ]
end
