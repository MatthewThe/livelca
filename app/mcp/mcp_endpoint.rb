# Rack endpoint for the MCP server, mounted at /mcp. Requests need the bearer token of an admin,
# generated on the profile page (McpTokensController). As a plain Rack app it bypasses the
# CSRF protection, sessions and params parsing of the Rails controllers.
class McpEndpoint
  INSTRUCTIONS = "Read and edit LiveLCA products, studies (sources), resources, recipes and ingredients. " \
                 "CO2e values are in kg CO2e per kg of product and are recomputed automatically on every edit."

  def self.call(env)
    token = env["HTTP_AUTHORIZATION"].to_s[/\ABearer (.+)\z/, 1]
    user = User.find_by_api_token(token)
    return [401, { "content-type" => "text/plain", "www-authenticate" => "Bearer" }, ["Unauthorized"]] unless user&.admin?

    server = MCP::Server.new(name: "livelca", instructions: INSTRUCTIONS, tools: AdminTools.all, server_context: { user: user })
    # Requests are authenticated by bearer token, which a DNS rebinding attack cannot supply
    MCP::Server::Transports::StreamableHTTPTransport.new(
      server, stateless: true, enable_json_response: true, dns_rebinding_protection: false, serve_subscriptions_listen: false
    ).call(env)
  end
end
