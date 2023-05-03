defmodule Cal.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CalWeb.Telemetry,
      # Start the Ecto repository
      Cal.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Cal.PubSub},
      # Start the Endpoint (http/https)
      CalWeb.Endpoint
      # Start a worker by calling: Cal.Worker.start_link(arg)
      # {Cal.Worker, arg}
    ]

    # Creating DETS token table
    # TokenTable.init()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cal.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
