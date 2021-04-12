defmodule SecFilings.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      SecFilings.Repo,
      # Start the Telemetry supervisor
      SecFilingsWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: SecFilings.PubSub},
      # Start the Endpoint (http/https)
      SecFilingsWeb.Endpoint,
      # Start a worker by calling: SecFilings.Worker.start_link(arg)
      #{SecFilings.ParserWorker, []},
      #{SecFilings.MemMon, []}
      # {SecFilings.Worker, arg}
      # {Cachex, [name: :filings_cache, limit: 20]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SecFilings.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SecFilingsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
