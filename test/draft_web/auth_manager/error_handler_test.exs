defmodule DraftWeb.AuthManager.ErrorHandlerTest do
  use DraftWeb.ConnCase

  describe "auth_error/3" do
    test "redirects to Cognito login", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> DraftWeb.AuthManager.ErrorHandler.auth_error({:some_type, :reason}, [])

      assert html_response(conn, 302) =~ "\"/auth/cognito\""
    end
  end
end
