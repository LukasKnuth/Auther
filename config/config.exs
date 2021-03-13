# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Knigge config
config :auther, Auther.Security.Password, Auther.Security.Password.Bcrypt
config :auther, Auther.Security.TwoFactorAuth, Auther.Security.TwoFactorAuth.TOTP

config :auther,
  ecto_repos: [Auther.Repo]

# Configures the endpoint
config :auther, AutherWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RD+hcJbNC26hQTwi8WlhgHaXbDAyt5wtVdIMfwOkKNhKdYUC+0xiypR1/ZcMvVLf",
  render_errors: [view: AutherWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Auther.PubSub,
  live_view: [signing_salt: "D8lu3Ir7"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Set bcrypt rounds for secure passwords
config :bcrypt_elixir, log_rounds: 12

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
