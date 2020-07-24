# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :auther,
  ecto_repos: [Auther.Repo]

# Configures the endpoint
config :auther, AutherWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "spVH5vYznV2B8v/mJH9doXytygmX9UlDxap2qoLJ2sZTRyhUGazd1dV9OJIa1oRQ",
  render_errors: [view: AutherWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Auther.PubSub,
  live_view: [signing_salt: "HKJaI6vV"],
  http: [
    protocol_options: [
      # The following seems to be required in order to stop errors like "413 couldn't parse headers, too long"
      max_request_line_length: 8192,
      max_header_value_length: 8192
    ]
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Setup user repo for Pow
config :auther, :pow,
       user: Auther.Users.User,
       repo: Auther.Repo

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
