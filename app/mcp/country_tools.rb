# Countries are referenced by name as the origin or consumption country of studies, ingredients and recipes
module CountryTools
  def self.summary(country)
    { id: country.id, name: country.name }
  end

  def self.details(country)
    summary(country).merge(wiki: country.wiki)
  end

  # Countries are referenced by name throughout the app, so names must stay unique
  def self.check_name_available(name, country = nil)
    existing = Country.find_by(name: name)
    raise AdminTools::Error, "Country \"#{name}\" already exists" if existing && existing != country
  end

  # Number of relationships to other nodes, by their label, e.g. { "Recipe" => 2 }
  def self.links(country)
    country.query_as(:c).match("(c)-[r]-(n)").pluck("labels(n)[0]", "count(r)").to_h
  end

  # Finds every country given by id or name, raising one error listing all that do not exist
  def self.find_all!(ids, names)
    found = ids.map { |id| [id, Country.find_by(id: id)] } + names.map { |name| [name, Country.find_by(name: name)] }
    missing = found.reject(&:last).map(&:first)
    raise AdminTools::Error, "Countries not found: #{missing.join(', ')}" if missing.any?
    found.map(&:last).uniq
  end

  ATTRIBUTES = [:name, :wiki]
  PROPERTIES = { name: { type: "string" }, wiki: { type: "string", description: "Markdown" } }

  ALL = [
    AdminTools.tool(
      name: "search_countries",
      description: "Find countries whose name contains the query (case-insensitive). For several names use match_names",
      properties: AdminTools::SEARCH_PROPERTIES,
      required: ["query"],
      read_only: true
    ) do |args, _user|
      AdminTools.search_by_name(Country, args).map { |c| summary(c) }
    end,

    AdminTools.tool(
      name: "get_country",
      description: "Get a country with its wiki",
      properties: { id: { type: "string", description: "Country UUID" } },
      required: ["id"],
      read_only: true
    ) do |args, _user|
      details(Country.find(args[:id]))
    end,

    AdminTools.tool(
      name: "create_country",
      description: "Create a country",
      properties: PROPERTIES,
      required: ["name"]
    ) do |args, _user|
      check_name_available(args[:name])
      details(AdminTools.save!(Country.new(args.slice(*ATTRIBUTES))))
    end,

    AdminTools.tool(
      name: "update_country",
      description: "Update a country; only the given fields are changed",
      properties: { id: { type: "string" } }.merge(PROPERTIES),
      required: ["id"]
    ) do |args, _user|
      country = Country.find(args[:id])
      check_name_available(args[:name], country) if args.key?(:name)
      country.assign_attributes(args.slice(*ATTRIBUTES))
      details(AdminTools.save!(country))
    end,

    AdminTools.tool(
      name: "delete_countries",
      description: "Delete countries, e.g. spam entries. Studies, ingredients, recipes and other nodes that referenced " \
                   "a deleted country lose that reference and show Unknown. The result lists each country's links by label",
      properties: {
        ids: { type: "array", items: { type: "string" }, description: "Country UUIDs" },
        names: { type: "array", items: { type: "string" }, description: "Exact country names" },
      },
      destructive: true
    ) do |args, _user|
      countries = find_all!(args.fetch(:ids, []), args.fetch(:names, []))
      raise AdminTools::Error, "Unknown is the default country and cannot be deleted" if countries.any? { |c| c.name == "Unknown" }
      countries.map do |country|
        result = summary(country).merge(links: links(country))
        country.destroy
        result
      end
    end,
  ]
end
