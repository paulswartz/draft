defmodule DraftWeb.AuthControllerTest do
  use DraftWeb.ConnCase

  alias DraftWeb.Router.Helpers

  describe "callback" do
    @tag :authenticated_admin
    test "redirects on success and saves username", %{conn: conn} do
      conn =
        conn
        |> get(Helpers.auth_path(conn, :callback, "cognito"))

      response = html_response(conn, 302)

      assert response =~ Helpers.page_path(conn, :index)
      assert Guardian.Plug.current_claims(conn)["groups"] == ["draft-admin"]
      assert Plug.Conn.get_session(conn, :username) == "fake_uid"
    end

    test "handles generic failure - 401", %{conn: conn} do
      conn =
        conn
        |> assign(:ueberauth_failure, %Ueberauth.Failure{})
        |> get(Helpers.auth_path(conn, :callback, "cognito"))

      response = response(conn, 401)

      assert response =~ "unauthenticated"
    end
  end

  describe "request" do
    test "redirects to auth callback", %{conn: conn} do
      conn = get(conn, Helpers.auth_path(conn, :request, "cognito"))

      response = response(conn, 302)

      assert response =~ Helpers.auth_path(conn, :callback, "cognito")
    end
  end
end
