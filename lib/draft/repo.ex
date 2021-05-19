defmodule Draft.Repo do
  use Ecto.Repo,
    otp_app: :draft,
    adapter: Ecto.Adapters.Postgres

  require Logger

  @doc """
  Set via the `:configure` option in the Draft.Repo configuration, a function
  invoked prior to each DB connection. `config` is the configured connection values
  and it returns a new set of config values to be used when connecting.
  """
  @spec before_connect(map()) :: map()
  def before_connect(config) do
    mod = Application.get_env(:draft, Draft.Repo)[:aws_rds_mod]

    if mod do
      :ok = Logger.info("generating_aws_rds_iam_auth_token")
      username = Keyword.fetch!(config, :username)
      hostname = Keyword.fetch!(config, :hostname)
      port = Keyword.fetch!(config, :port)
      token = apply(mod, :generate_db_auth_token, [hostname, username, port, %{}])
      :ok = Logger.info("generated_aws_rds_iam_auth_token")

      Keyword.put(config, :password, token)
    else
      config
    end
  end
end
