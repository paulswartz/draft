defmodule DraftWeb.AuthController do
  use DraftWeb, :controller

  alias DraftWeb.AuthManager
  alias DraftWeb.Router.Helpers

  plug(Ueberauth)
  require Logger

  @spec callback(Plug.Conn.t(), any) :: Plug.Conn.t()
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    username = auth.uid
    credentials = auth.credentials
    expiration = credentials.expires_at

    current_time = System.system_time(:second)

    conn
    |> Guardian.Plug.sign_in(
      AuthManager,
      username,
      %{groups: credentials.other[:groups]},
      ttl: {expiration - current_time, :seconds}
    )
    |> Plug.Conn.put_session(:username, username)
    |> redirect(to: Helpers.page_path(conn, :index))
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    require Logger
    Logger.error(_fails)
    send_resp(conn, 401, "unauthenticated testing")
  end
end
