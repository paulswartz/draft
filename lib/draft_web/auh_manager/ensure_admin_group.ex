defmodule DraftWeb.EnsureAdminGroup do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    claims = Guardian.Plug.current_claims(conn)

    if DraftWeb.AuthManager.claims_access_level(claims) == :admin do
      conn
    else
      conn
      |> Phoenix.Controller.redirect(to: DraftWeb.Router.Helpers.page_path(conn, :index)) # Redirect to unauthorized page instead
      |> halt()
    end
  end
end
