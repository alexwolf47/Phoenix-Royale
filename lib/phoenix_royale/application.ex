defmodule PhoenixRoyale.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      PhoenixRoyale.Repo,
      # Start the endpoint when the application starts
      PhoenixRoyaleWeb.Endpoint,
      # Starts a worker by calling: PhoenixRoyale.Worker.start_link(arg)
      # {PhoenixRoyale.Worker, arg},
      PhoenixRoyale.GameCoordinator,
      PhoenixRoyale.GameChat
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixRoyale.Supervisor]

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PhoenixRoyaleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
