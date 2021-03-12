defmodule Auther.Repo do
  use Ecto.Repo,
    otp_app: :auther,
    adapter: Ecto.Adapters.Postgres
end
