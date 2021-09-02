import Config

config :draft, Draft.Repo,
  username: System.get_env("DATABASE_USER"),
  database: System.get_env("DATABASE_NAME"),
  hostname: System.get_env("DATABASE_HOST"),
  password: System.get_env("DATABASE_PASSWORD"),
  port: "DATABASE_PORT" |> System.get_env("5432") |> String.to_integer(),
  configure: {Draft.Repo, :before_connect, []}

config :draft, DraftWeb.AuthManager, secret_key: System.get_env("DRAFT_AUTH_SECRET")

config :draft, DraftWeb.Endpoint,
  url: [host: System.get_env("HOST"), port: 80],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :ueberauth, Ueberauth.Strategy.Cognito,
  auth_domain: System.get_env("COGNITO_DOMAIN"),
  client_id: System.get_env("COGNITO_CLIENT_ID"),
  client_secret: System.get_env("COGNITO_CLIENT_SECRET"),
  user_pool_id: System.get_env("COGNITO_USER_POOL_ID"),
  aws_region: System.get_env("COGNITO_AWS_REGION")

if bucket = System.get_env("IMPORTER_S3_BUCKET") do
  prefix = System.get_env("IMPORTER_S3_PREFIX") || ""
  schedule = System.get_env("IMPORTER_SCHEDULE") || "* * * * *"

  queue_size =
    case System.get_env("IMPORTER_QUEUE_SIZE") do
      bin when is_binary(bin) -> String.to_integer(bin)
      _default -> 1
    end

  config :draft, Oban,
    queues: [importer: queue_size],
    plugins: [
      {Oban.Plugins.Cron,
       crontab: [
         {
           schedule,
           Draft.Importer.S3ScanWorker,
           args: %{bucket: bucket, prefix: prefix}
         }
       ]}
    ]
end
