defmodule DraftWeb.AuthManager.EnsureAdminGroupTest do
  use DraftWeb.ConnCase

  alias DraftWeb.AuthManager.EnsureAdminGroup

  describe "call/2" do
    test "redirects if no admin access", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> EnsureAdminGroup.call({:some_type, :reason})

      assert html_response(conn, 302) =~ "\"/\""
    end

    @tag :authenticated_admin
    test "does nothing if in draft-admin group", %{conn: conn} do
      assert conn == EnsureAdminGroup.call(conn, [])
    end
  end

  describe "init/1" do
    test "init passes through options" do
      assert EnsureAdminGroup.init([]) == []
    end
  end
end
