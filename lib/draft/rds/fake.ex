defmodule Draft.Rds.Fake do
  @moduledoc """
  Fake RDS module for mocking generating an auth token for connecting to
  a DB with IAM credentials.
  """
  def generate_db_auth_token(_, _, _, _) do
    "iam_token"
  end
end
