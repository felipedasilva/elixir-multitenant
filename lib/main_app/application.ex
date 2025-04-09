defmodule MainApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MainAppWeb.Telemetry,
      MainApp.Repo,
      {DNSCluster, query: Application.get_env(:main_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MainApp.PubSub},
      # Start a worker by calling: MainApp.Worker.start_link(arg)
      # {MainApp.Worker, arg},
      # Start to serve requests, typically the last entry
      MainAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MainApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MainAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
