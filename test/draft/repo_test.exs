defmodule Draft.RepoTest do
  use ExUnit.Case, async: true

  describe "before_connect/1" do
    test "generates RDS IAM auth token" do
      config = Draft.Repo.before_connect(username: "u", hostname: "h", port: 4000)
      assert Keyword.fetch!(config, :password) == "iam_token"
    end
  end
end
