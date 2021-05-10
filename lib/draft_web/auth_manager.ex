defmodule DraftWeb.AuthManager do
  use Guardian, otp_app: :draft

  @type access_level :: :none | :operator | :admin

  @draft_admin_group "draft-admin"

  require Logger

  def subject_for_token(resource, _claims) do
    {:ok, resource}
  end

  @spec resource_from_claims(any) :: {:error, :invalid_claims} | {:ok, any}
  def resource_from_claims(%{"sub" => username}) do
    {:ok, username}
  end

  def resource_from_claims(_), do: {:error, :invalid_claims}

  @spec claims_access_level(Guardian.Token.claims()) :: access_level()
  def claims_access_level(%{"groups" => groups}) do
    if not is_nil(groups) and @draft_admin_group in groups do
      :admin
    else
      :operator
    end
  end

  def claims_access_level(_claims) do
    :none # Skate had this as :general (analogous to our :operator), when would this be hit? No groups?
  end
end
