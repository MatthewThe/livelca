class McpTokensController < ApplicationController
  before_action :authenticate_user!, :is_admin

  # POST /mcp_token
  # Renders the new token instead of redirecting, so it is shown once and never stored in the flash
  def create
    @token = current_user.regenerate_api_token
    response.headers["Cache-Control"] = "no-store"
  end

  # DELETE /mcp_token
  def destroy
    current_user.revoke_api_token
    redirect_to edit_user_registration_path, notice: 'MCP token was revoked.'
  end
end
