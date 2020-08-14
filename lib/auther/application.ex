defmodule Auther.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Auther.Repo,
      # Start the Registry for 2-step OAuth
      Auther.OAuth.Store.Registry,
      # Start the Telemetry supervisor
      AutherWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Auther.PubSub},
      # Start the Endpoint (http/https)
      AutherWeb.Endpoint
      # Start a worker by calling: Auther.Worker.start_link(arg)
      # {Auther.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Auther.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AutherWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
