defmodule DraftWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use DraftWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  import Plug.Test

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import DraftWeb.ConnCase

      alias DraftWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint DraftWeb.Endpoint
    end
  end

  setup tags do
    alias Ecto.Adapters.SQL.Sandbox
    :ok = Sandbox.checkout(Draft.Repo)

    unless tags[:async] do
      Sandbox.mode(Draft.Repo, {:shared, self()})
    end

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("x-forwarded-proto", "https")

    cond do
      tags[:authenticated] ->
        user = "test_user"

        conn =
          conn
          |> init_test_session(%{username: user})
          |> Guardian.Plug.sign_in(DraftWeb.AuthManager, user, %{})

        {:ok, conn: conn}

      tags[:authenticated_admin] ->
        user = "test_user"

        conn =
          conn
          |> init_test_session(%{})
          |> Guardian.Plug.sign_in(DraftWeb.AuthManager, user, %{groups: ["draft-admin"]})

        {:ok, conn: conn}

      true ->
        {:ok, conn: conn}
    end
  end
end
