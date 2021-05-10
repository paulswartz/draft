defmodule DraftWeb.AuthManager.ErrorHandler do
  @moduledoc """
  Handle auth errors
  """
  @behaviour Guardian.Plug.ErrorHandler

  alias DraftWeb.Router.Helpers

  require Logger

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _opts) do
    Phoenix.Controller.redirect(
      conn,
      to: Helpers.auth_path(conn, :request, "cognito")
    )
  end
end
