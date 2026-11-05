# Prompts exposed through the MCP endpoint, shown as slash commands by clients such as Claude Code
module AdminPrompts
  FULL_TEXT = <<~TEXT.chomp
    First make sure you can read the full article, not just its abstract or landing page. If you cannot,
    stop and ask me for the PDF before doing anything else.
  TEXT

  LIST_NEW_RESOURCES = <<~TEXT
    List the studies cited in %{paper} that are not yet in LiveLCA. Do not create or change anything.
    #{FULL_TEXT}

    1. Extract every row of the table: the cited study and its product. Look up each cited study in the
       reference list for its title and its DOI or link.
    2. Call match_names once with all studies (by title, and by DOI as a fallback) and all products.
    3. Show me a table of the studies without a matching resource, with the columns: study (its title,
       linked to its DOI or link), number of products, and products (by their LiveLCA name, marking those
       without a match). Group EPDs into one row per manufacturer, with the number of EPDs in the study
       column. Sort by number of products, most first.
  TEXT

  IMPORT_RESOURCE = <<~TEXT
    Import the CO2e values that %{paper} reports from its own data into LiveLCA as a single resource.
    #{FULL_TEXT}

    1. Extract every product the paper reports emissions for: product, CO2e value, CO2, CH4 and N2O emissions
       if given separately, and countries of origin and consumption. Note the functional unit and system
       boundary (e.g. per kg live weight, per kg FPCM, per litre, farm gate) and convert each value to
       kg CO2e per kg of product. Put the original value, unit, system boundary and conversion in the
       source's notes. If the paper reports several farms, scenarios or years, extract each of them.
    2. Call match_names once with the paper's title (and DOI as a fallback), the products and the countries.
       If the resource already exists, show me its sources and stop. For products or countries without a
       match, propose the closest candidate or a new product.
    3. Call create_resource with all sources and dry_run: true. Its name is the paper's title and its url
       the DOI or link. Set the quality ratings from the paper itself (meta_study: no, year_of_study from
       when the data was collected, commissioned from its funding statement). If several sources are for
       the same LiveLCA product, pick the most representative one, give the others weight: 0 and say in
       their notes why. Show me the result, including the conversions and the product CO2e changes.
    4. End your turn and wait for my reply; this request is not approval of any entries. Only when I
       explicitly approve the shown entries, repeat the same call without dry_run. If I ask for changes,
       show a new dry run first.
  TEXT

  # The same workflows for agents, which cannot fetch prompts themselves (see WorkflowTools)
  WORKFLOWS = {
    "import_resource" => IMPORT_RESOURCE,
    "list_new_resources" => LIST_NEW_RESOURCES,
  }

  def self.workflow(name, paper)
    format(WORKFLOWS.fetch(name), paper: paper)
  end

  def self.define(name, description, template, paper_description)
    MCP::Prompt.define(
      name: name,
      description: description,
      arguments: [MCP::Prompt::Argument.new(name: "paper", description: paper_description, required: true)]
    ) do |args|
      MCP::Prompt::Result.new(
        description: description,
        messages: [MCP::Prompt::Message.new(role: "user", content: MCP::Content::Text.new(format(template, paper: args[:paper])))]
      )
    end
  end

  def self.all
    [
      define("list_new_resources",
             "List the studies cited in a paper's table that are not yet in LiveLCA, with their products",
             LIST_NEW_RESOURCES, "The paper and table, e.g. \"Table 3 of the attached paper\""),
      define("import_resource",
             "Add a paper that reports its own CO2e data as a single resource with its sources after approval",
             IMPORT_RESOURCE, "The paper, e.g. \"the attached paper\" or its DOI"),
    ]
  end
end
