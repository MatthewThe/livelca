# Tools exposed to authenticated admins through the MCP endpoint (see McpEndpoint).
# Each *Tools module defines an ALL list of MCP::Tool classes built with AdminTools.tool.
module AdminTools
  class Error < StandardError; end

  def self.all
    MatchTools::ALL + ProductTools::ALL + SourceTools::ALL + ResourceTools::ALL + RecipeTools::ALL + IngredientTools::ALL
  end

  SEARCH_PROPERTIES = {
    query: { type: "string" },
    limit: { type: "integer", minimum: 1, maximum: 100, default: 25 },
  }

  DRY_RUN_PROPERTY = {
    dry_run: { type: "boolean", default: false, description: "Return the result without saving anything, e.g. to show it to the user for approval" },
  }

  # Defines an MCP tool whose block receives the symbolized arguments and the admin user.
  # Write tools get a dry_run argument and run in a transaction, so a failing lookup or validation
  # leaves the graph unchanged. Lookup failures and validation errors are returned as tool errors.
  def self.tool(name:, description:, properties: {}, required: [], read_only: false, destructive: false, &block)
    MCP::Tool.define(
      name: name,
      description: description,
      input_schema: { properties: read_only ? properties : properties.merge(DRY_RUN_PROPERTY), required: required },
      annotations: { read_only_hint: read_only, destructive_hint: destructive, open_world_hint: false }
    ) do |server_context:, dry_run: false, **args|
      user = server_context[:user]
      result = read_only ? block.call(args, user) : AdminTools.write(dry_run) { block.call(args, user) }
      MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(result) }])
    rescue Error, ActiveGraph::RecordNotFound => e
      MCP::Tool::Response.new([{ type: "text", text: e.message }], error: true)
    end
  end

  # Runs the block in a transaction, which a dry run rolls back after building the result
  def self.write(dry_run)
    result = nil
    ActiveGraph::Base.transaction do
      result = yield
      raise ActiveGraph::Rollback if dry_run
    end
    return { dry_run: true, note: "Nothing was saved; ids in the result will not exist", result: result } if dry_run
    expire_caches
    result
  end

  def self.expire_caches
    ProductsController.expire_page("/product_table.json")
    ProductsController.expire_page("/product_graph_json.json")
    RecipesController.expire_page("/recipe_table.json")
  end

  # Unlike the web forms, tools never create referenced products or countries implicitly,
  # so a typo in a name cannot add a new node to the graph.
  def self.find_by_name!(model, name)
    model.find_by(name: name) || raise(Error, "#{model.name} \"#{name}\" not found")
  end

  # Raises one error listing every name that does not exist, given as { Model => [names] }
  def self.check_names_exist!(names_by_model)
    messages = names_by_model.filter_map do |model, names|
      missing = names.compact.uniq.reject { |name| model.find_by(name: name) }
      "#{model.name.pluralize} not found: #{missing.join(', ')}" if missing.any?
    end
    raise Error, messages.join("; ") if messages.any?
  end

  def self.find_country(name)
    find_by_name!(Country, name.presence || "Unknown")
  end

  def self.save!(record)
    return record if record.save
    raise Error, "Could not save #{record.class.name}: #{record.errors.full_messages.join(', ')}"
  end

  # Case-insensitive substring search on name
  def self.search_by_name(model, args)
    model.where(name: /.*#{Regexp.escape(args[:query])}.*/i).limit(args.fetch(:limit, 25))
  end
end
