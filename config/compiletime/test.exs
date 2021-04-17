import Config

# Knigge config
config :auther, Auther.Security.Password, Auther.Security.Password.Mock
config :auther, Auther.Security.TwoFactorAuth, Auther.Security.TwoFactorAuth.Mock

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :auther, Auther.Repo,
  username: "postgres",
  password: "postgres",
  database: "auther_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :auther, AutherWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# TEST ONLY: reduce bcrypt rounds to speed up test-execution
config :bcrypt_elixir, :log_rounds, 4
