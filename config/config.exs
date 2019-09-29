# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :phoenix_royale,
  ecto_repos: [PhoenixRoyale.Repo]

# Configures the endpoint
config :phoenix_royale, PhoenixRoyaleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RaYpLSw1ARJ4lyMoxEz4R9jH4udPC25YdbaxE2QcdU1j1ILK14gLSDqgNGDVVFG5",
  render_errors: [view: PhoenixRoyaleWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: PhoenixRoyale.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "RaYpLSw1ARJ4lyMoxEz4R9jH4udPC25YdbaxE2QcdU1j1ILK14gLSDqgNGDVVFG5"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
