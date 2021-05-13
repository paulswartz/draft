defmodule Draft.RepoTest do
  use ExUnit.Case, async: false

  defmodule FakeAwsRds do
    def generate_db_auth_token(_, _, _, _) do
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
      Application.put_env(:draft, :aws_rds_mod, nil)
    end
  end
end
