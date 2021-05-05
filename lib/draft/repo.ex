defmodule Draft.Repo do
  use Ecto.Repo,
    otp_app: :draft,
    adapter: Ecto.Adapters.Postgres
end
