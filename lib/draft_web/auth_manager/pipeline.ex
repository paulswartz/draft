defmodule DraftWeb.AuthManager.Pipeline do
  @moduledoc """
  Pipeline for locating the token. This module only finds a token if it exists, it does *not* check if
  that token meets a certain access level.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :draft,
    error_handler: DraftWeb.AuthManager.ErrorHandler,
    module: DraftWeb.AuthManager

  plug(Guardian.Plug.VerifySession, claims: %{"typ" => "access"})
  plug(Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"})
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end
