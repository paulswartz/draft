defmodule DraftWeb.AuthManager.EnsureAdminGroup do
  @moduledoc """
  Ensure the user is part of the draft-admin user group.
  """
  import Plug.Conn

  alias DraftWeb.Router.Helpers

  def init(options), do: options

  def call(conn, _opts) do
    claims = Guardian.Plug.current_claims(conn)

    if DraftWeb.AuthManager.claims_access_level(claims) == :admin do
      conn
    else
      conn
      # Redirect to unauthorized page instead?
      |> Phoenix.Controller.redirect(to: Helpers.page_path(conn, :index))
      |> halt()
    end
  end
end
