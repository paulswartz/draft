defmodule DraftWeb.HealthControllerTest do
  use DraftWeb.ConnCase, async: true

  describe "index/2" do
    test "returns 200", %{conn: conn} do
      conn = get(conn, "/_health")
      assert %{status: 200} = get(conn, "/_health")
    end
  end
end
