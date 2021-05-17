defmodule DraftWeb.AuthManager do
  @moduledoc """
  AuthManager is a guardian implementation for token verification.
  """
  use Guardian, otp_app: :draft

  @type access_level :: :none | :operator | :admin

  @draft_admin_group "draft-admin"

  @spec subject_for_token(
          resource :: Guardian.Token.resource(),
          claims :: Guardian.Token.claims()
        ) :: {:ok, String.t()} | {:error, atom()}
  def subject_for_token(resource, _claims) do
    {:ok, resource}
  end

  @spec resource_from_claims(claims :: Guardian.Token.claims()) ::
          {:error, :invalid_claims} | {:ok, String.t()}
  def resource_from_claims(%{"sub" => username}) do
    {:ok, username}
  end

  def resource_from_claims(_claims), do: {:error, :invalid_claims}

  @spec claims_access_level(Guardian.Token.claims()) :: access_level()
  def claims_access_level(%{"groups" => groups}) do
    if not is_nil(groups) and @draft_admin_group in groups do
      :admin
    else
      :operator
    end
  end

  def claims_access_level(_claims) do
    :none
  end
end
