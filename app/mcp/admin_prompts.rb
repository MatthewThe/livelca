# Prompts exposed through the MCP endpoint, shown as slash commands by clients such as Claude Code
module AdminPrompts
  IMPORT_STUDIES = <<~TEXT
    Import the CO2e studies from %{paper} into LiveLCA:

    1. Extract every row of the table: the cited study (resource), product, CO2e value in kg CO2e per kg
       of product, and countries of origin and consumption if given. Convert other units to kg CO2e per kg.
       Look up each cited study in the reference list: its resource name is the title of the article,
       report or database, not the authors, and its url is the DOI or link.
    2. Call match_names once with all resources (by title, and by DOI as a fallback), products and countries.
    3. List which resources are already included (compare their sources with the table) and which are missing.
       For products or countries without a match, propose the closest candidate or a new product.
    4. For the first missing resource, call create_resource with all its sources and dry_run: true, set the
       quality ratings from what the paper says about the study, and show me the result, including the
       product CO2e changes.
    5. End your turn and wait for my reply; this request is not approval of any entries. Only when I explicitly
       approve the shown entries, repeat the same call without dry_run, then continue with the next resource
       starting again at step 4. If I ask for changes, show a new dry run first.
  TEXT

  def self.all
    [
      MCP::Prompt.define(
        name: "import_studies",
        description: "Find studies in a paper's table that are not yet in LiveLCA and add them one resource at a time after approval",
        arguments: [MCP::Prompt::Argument.new(name: "paper", description: "The paper and table, e.g. \"Table 3 of the attached paper\"", required: true)]
      ) do |args|
        MCP::Prompt::Result.new(
          description: "Import studies from #{args[:paper]}",
          messages: [MCP::Prompt::Message.new(role: "user", content: MCP::Content::Text.new(format(IMPORT_STUDIES, paper: args[:paper])))]
        )
      end,
    ]
  end
end
