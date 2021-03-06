defmodule Draft.RepoTest do
  use ExUnit.Case, async: false

  defmodule FakeAwsRds do
    @spec generate_db_auth_token(
            hostname :: String.t(),
            username :: String.t(),
            port :: integer(),
            config :: map()
          ) :: String.t()
    def generate_db_auth_token(_username, _hostname, _port, _config) do
      "iam_token"
    end
  end

  describe "before_connect/1" do
    test "uses given password if no rds module configured" do
      config =
        Draft.Repo.before_connect(username: "u", hostname: "h", port: 4000, password: "pass")

      assert Keyword.fetch!(config, :password) == "pass"
    end

    test "generates RDS IAM auth token if rds module is configured" do
      Application.put_env(:draft, :aws_rds_mod, FakeAwsRds)
      config = Draft.Repo.before_connect(username: "u", hostname: "h", port: 4000)
      assert Keyword.fetch!(config, :password) == "iam_token"
      on_exit(fn -> Application.put_env(:draft, :aws_rds_mod, nil) end)
    end
  end
end
