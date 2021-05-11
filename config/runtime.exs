import Config

config :draft, Draft.Repo,
  username: System.get_env("DATABASE_USER"),
  password: System.get_env("DATABASE_PASSWORD"),
  database: System.get_env("DATABASE_NAME"),
  hostname: System.get_env("DATABASE_HOST")

config :draft, DraftWeb.AuthManager, secret_key: System.get_env("DRAFT_AUTH_SECRET")

config :draft, DraftWeb.Endpoint,
  url: [host: System.get_env("HOST"), port: 80],
  secret_key_base: System.get_env("SECRET_KEY_BASE")
