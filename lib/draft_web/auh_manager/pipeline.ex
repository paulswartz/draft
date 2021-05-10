defmodule DraftWeb.AuthManager.Pipeline do

  require Logger
  use Guardian.Plug.Pipeline,
    otp_app: :draft,
    error_handler: DraftWeb.AuthManager.ErrorHandler,
    module: DraftWeb.AuthManager

  plug(Guardian.Plug.VerifySession, claims: %{"typ" => "access"})
  plug(Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"})
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end
