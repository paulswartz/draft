defmodule Skate.Ueberauth.Strategy.FakeTest do
  use ExUnit.Case, async: true

  alias Draft.Ueberauth.Strategy.Fake
  alias Ueberauth.Auth.{Credentials, Extra, Info}

  test "credentials returns a credentials struct" do
    assert Fake.credentials(%{}) == %Credentials{
             token: "fake_access_token",
             refresh_token: "fake_refresh_token",
             other: %{groups: ["draft-admin"]},
             expires: true,
             expires_at: System.system_time(:second) + 9 * 60 * 60
           }
  end

  test "info returns an empty Info struct" do
    assert Fake.info(%{}) == %Info{}
  end

  test "extra returns an Extra struct with empty raw_info" do
    assert Fake.extra(%{}) == %Extra{raw_info: %{}}
  end
end
