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
  ]
end
