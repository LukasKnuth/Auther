defmodule Auther.Fixtures do
  alias Auther.Accounts.User
  alias Auther.Accounts.TwoFactorAuth
  alias Auther.Repo

  @pw_hash Auther.Security.Password.Bcrypt.hash("asdf1234")
  @tfa_secret Auther.Security.TwoFactorAuth.TOTP.generate_secret()

  def fixture(:user) do
    %User{name: Faker.Person.name(), email: Faker.Internet.email(), password_hash: @pw_hash}
    |> Repo.insert!()
    # pretend like 2FA is preloaded
    |> Map.put(:two_factor_auth, nil)
  end

  def fixture(:user_with_tfa) do
    %User{
      name: Faker.Person.name(),
      email: Faker.Internet.email(),
      password_hash: @pw_hash,
      two_factor_auth: %TwoFactorAuth{secret: @tfa_secret, fallback: ["something"]}
    }
    |> Repo.insert!()
  end
end
