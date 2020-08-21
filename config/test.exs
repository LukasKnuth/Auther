import Config

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

config :joken,
  current_time_adapter: Auther.Mock.JwtTokenTime,
  jwt_token: [
    signer_alg: "ES256",
    key_pem: """
    -----BEGIN EC PRIVATE KEY-----
    MHYCAQEEHz3Mo9EeR361N+38ztxNpYBbZpASxep/NQezNkxQotGgCgYIKoZIzj0D
    AQehRANCAARXKWDrCdqT7bHZq+zozi1eMeDGoQv6QgKy2XvetVcg045MJ3MUG6Nv
    zzmsVe/xBK0wIQcyXo+Z63FXptepILZL
    -----END EC PRIVATE KEY-----
    """
  ]
