# Serves the AdminPrompts workflows as a tool, so that agents and skills can follow the current version
# instead of a copy. MCP prompts can only be started by the user, not fetched by the model.
module WorkflowTools
  ALL = [
    AdminTools.tool(
      name: "get_workflow",
      description: "Get the steps for a LiveLCA workflow, the same text as the prompt of the same name: import_resource " \
                   "(add a paper's own CO2e data as one resource) or list_new_resources (list the studies cited in a " \
                   "paper's table and text that are not yet in LiveLCA). Changes nothing; follow the returned steps with the other tools",
      properties: {
        name: { type: "string", enum: AdminPrompts::WORKFLOWS.keys },
        paper: { type: "string", description: "The paper (and table), e.g. \"Table 3 of the attached paper\"; defaults to \"the paper\"" },
      },
      required: ["name"],
      read_only: true
    ) do |args, _user|
      { workflow: args[:name], steps: AdminPrompts.workflow(args[:name], args[:paper].presence || "the paper") }
    end,
  ]
end
