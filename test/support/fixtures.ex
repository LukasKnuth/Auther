defmodule Auther.Fixtures do
  alias Auther.Accounts.User
  alias Auther.Accounts.TwoFactorAuth
  alias Auther.Repo

  @pw_hash Auther.Security.Password.Bcrypt.hash("asdf1234")
  @tfa_secret Auther.Security.TwoFactorAuth.TOTP.generate_secret()

  @doc """
  Returns a valid, randomized and database-inserted fixture of the given type.
  Optional overrides can be specified to customize the inserted/returned fixture.
  """
  def fixture(type, overrides \\ [])

  def fixture(:user, overrides) do
    user(overrides)
    |> Repo.insert!()
  end

  def fixture(:user_with_tfa, overrides) do
    %{
      user(overrides)
      | two_factor_auth: %TwoFactorAuth{
        secret: @tfa_secret,
        fallback: ["something"],
        intrusiveness: Keyword.get(overrides, :intrusiveness, :balanced)
      }
    }
    |> Repo.insert!()
  end

  defp user(overrides) do
    %User{
      name: Keyword.get_lazy(overrides, :name, &Faker.Person.name/0),
      email: Keyword.get_lazy(overrides, :email, &Faker.Internet.email/0),
      password_hash: @pw_hash,
      two_factor_auth: nil
    }
  end
end
