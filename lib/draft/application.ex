defmodule Draft.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Draft.Repo,
      # Start the Telemetry supervisor
      DraftWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Draft.PubSub},
      # Start the Endpoint (http/https)
      DraftWeb.Endpoint
      # Start a worker by calling: Draft.Worker.start_link(arg)
      # {Draft.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Draft.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @spec config_change(any, any, any) :: :ok
  def config_change(changed, _new, removed) do
    DraftWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
