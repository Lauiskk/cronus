defmodule Cronus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CronusWeb.Telemetry,
      Cronus.Repo,
      {DNSCluster, query: Application.get_env(:cronus, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Cronus.PubSub},
      # Start a worker by calling: Cronus.Worker.start_link(arg)
      # {Cronus.Worker, arg},
      # Start to serve requests, typically the last entry
      CronusWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cronus.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CronusWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
