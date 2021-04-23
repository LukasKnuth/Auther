import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :auther, Auther.Repo, url: database_url

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :auther, AutherWeb.Endpoint, secret_key_base: secret_key_base

encryption_key = case System.get_env("ENCRYPTION_KEY") do
  nil -> raise """
  environment variable ENCRYPTION KEY is missing.
  To generate one, run iex> :crypto.strong_rand_bytes(32) |> Base.encode64()
  """

  key -> Auther.Security.Encryption.AES.validate_key!()
end

config :auther, Auther.Security.Encryption.AES, secret_key: encryption_key
