defmodule Auther.Fixtures do
  alias Auther.Accounts.User
  alias Auther.Repo

  @pw_hash Auther.Security.Password.Bcrypt.hash("asdf1234")

  def fixture(:user) do
    %User{name: "Lukas", email: "lukas@test.de", password_hash: @pw_hash}
    |> Repo.insert!()
    # pretend like 2FA is preloaded
    |> Map.put(:two_factor_auth, nil)
  end
end
