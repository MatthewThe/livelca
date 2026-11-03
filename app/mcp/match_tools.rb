# Bulk lookup of names, e.g. all studies and products of a table in a paper, in a single call
module MatchTools
  MAX_NAMES = 200
  MAX_CANDIDATES = 5

  def self.exact(model, name)
    model.where(name: /^#{Regexp.escape(name.strip)}$/i).first
  end

  # Records whose name contains one of the words of the given name, for names without an exact match.
  # Longer words are shortened to match plurals and small typos, e.g. "Tomatos" finds "Tomato".
  def self.candidates(model, name)
    words = name.scan(/[[:alpha:]][[:alnum:]-]{3,}/).map { |word| Regexp.escape(word.length > 5 ? word[0..-3] : word) }
    return [] if words.empty?
    model.where(name: /.*(#{words.join('|')}).*/i).limit(MAX_CANDIDATES).to_a
  end

  def self.match_product(name)
    product = exact(Product, name)
    return { name: name, match: ProductTools.summary(product), via: "name" } if product

    product_alias = ProductAlias.where(name: /^#{Regexp.escape(name.strip)}$/i).with_associations(:product).to_a.find { |a| a.product && a.product.name != "None" }
    return { name: name, match: ProductTools.summary(product_alias.product), via: "alias" } if product_alias

    { name: name, match: nil, candidates: candidates(Product, name).map { |p| ProductTools.summary(p) } }
  end

  # Resources are matched by name, or by URL when given a URL or DOI
  def self.match_resource(name)
    resource = exact(Resource, name)
    resource ||= Resource.where(url: /.*#{Regexp.escape(name.strip)}.*/i).first if name.include?("/")
    if resource
      sources = resource.sources.with_associations(:product, :country_origin, :country_consumption).map { |s| SourceTools.details(s).except(:resource) }
      return { name: name, match: ResourceTools.summary(resource).merge(sources: sources) }
    end

    { name: name, match: nil, candidates: candidates(Resource, name).map { |r| ResourceTools.summary(r) } }
  end

  def self.match_country(name)
    country = exact(Country, name)
    return { name: name, match: country.name } if country

    { name: name, match: nil, candidates: candidates(Country, name).map(&:name) }
  end

  NAMES_PROPERTY = { type: "array", items: { type: "string" }, maxItems: MAX_NAMES }

  ALL = [
    AdminTools.tool(
      name: "match_names",
      description: "Look up many names at once; use this instead of the search tools whenever there is more than one name " \
                   "to check, e.g. all studies and products of a table in a paper. Exact matches are case-insensitive; " \
                   "products also match via their aliases and resources via a URL or DOI. Matched resources include " \
                   "their sources, unmatched names include candidates with similar names",
      properties: {
        products: NAMES_PROPERTY.merge(description: "Product names"),
        resources: NAMES_PROPERTY.merge(description: "Resource names (e.g. \"Poore & Nemecek 2018\"), URLs or DOIs"),
        countries: NAMES_PROPERTY.merge(description: "Country names"),
      },
      read_only: true
    ) do |args, _user|
      {
        products: args.fetch(:products, []).map { |name| match_product(name) },
        resources: args.fetch(:resources, []).map { |name| match_resource(name) },
        countries: args.fetch(:countries, []).map { |name| match_country(name) },
      }
    end,
  ]
end
