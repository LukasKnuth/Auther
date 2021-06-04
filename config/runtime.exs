# In this file, we load production configuration and secrets
# from environment variables.
import Config

config :auther, Auther.Repo, pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :auther, AutherWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ]

# Load runtime config for specific environment, if it exists.
env_config = "runtime/#{config_env()}.exs"

if File.exists?(env_config) do
  import_config env_config
end

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :auther, AutherWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
