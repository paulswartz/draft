# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :draft,
  ecto_repos: [Draft.Repo]

config :draft, Draft.Repo,
  show_sensitive_data_on_connection_error: false,
  pool_size: 10

# Configures the endpoint
config :draft, DraftWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: DraftWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Draft.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

  config :ueberauth, Ueberauth,
  providers: [
    cognito: {Ueberauth.Strategy.Cognito, []}
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
