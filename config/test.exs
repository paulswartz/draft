use Mix.Config

# Configure your database
config :draft, Draft.Repo,
  show_sensitive_data_on_connection_error: true,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :draft, DraftWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :ueberauth, Ueberauth,
  providers: [
    cognito: {Draft.Ueberauth.Strategy.Fake, []}
  ]
