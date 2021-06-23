defmodule Auther.Accounts do
  @moduledoc """
  Context for accessing and manipulating User Accounts with Auther.
  """

  import Ecto.Query, warn: false
  alias Auther.Repo

  alias Auther.Accounts.User
  alias Auther.Accounts.TwoFactorAuth
  alias Auther.Security

  @fallback_count Application.compile_env!(:auther, [__MODULE__, :fallback_count])

  def get_user!(id) do
    User
    |> Repo.get!(id)
    |> user_preload()
  end

  def get_user_by(clauses) do
    case Repo.get_by(User, clauses) do
      nil -> :error
      %User{} = user -> {:ok, user_preload(user)}
    end
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset_for_create(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset_for_update(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @spec enable_2fa(%User{}, String.t(), String.t()) ::
          {:ok, %User{}, [String.t()]} | {:error, {:otp, :invalid}}
  def enable_2fa(%User{} = user, secret, confirmation) do
    if Security.TwoFactorAuth.validate(confirmation, secret, []) == {:valid, :otp} do
      {fallbacks_plain, fallbacks_hashed} = roll_fallbacks()

      user =
        user
        |> user_preload()
        |> User.changeset_for_enable_2fa(%{secret: secret, fallback: fallbacks_hashed})
        |> Repo.update!()

      {:ok, user, fallbacks_plain}
    else
      {:error, {:otp, :invalid}}
    end
  end

  def disable_2fa(%User{} = user) do
    user
    |> user_preload()
    |> User.changeset_for_disable_2fa()
    |> Repo.update()
  end

  def has_2fa?(%User{} = user) do
    user
    |> user_preload()
    |> case do
      %User{two_factor_auth: tfa} when is_nil(tfa) -> false
      %User{two_factor_auth: %TwoFactorAuth{}} -> true
    end
  end

  @spec verify_2fa(%User{}, String.t()) :: :invalid | :valid | {:valid, {:fallback, [String.t()]}}
  def verify_2fa(%User{} = user, otp_code) do
    user = user_preload(user)
    %User{two_factor_auth: %TwoFactorAuth{secret: secret, fallback: fallback}} = user

    case Security.TwoFactorAuth.validate(otp_code, secret, fallback) do
      :invalid ->
        :invalid

      {:valid, :otp} ->
        :valid

      {:valid, {:fallback, []}} ->
        {plain, hashed} = roll_fallbacks()
        update_2fa_fallbacks!(user, hashed)
        {:valid, {:fallback, plain}}

      {:valid, {:fallback, new_fallbacks}} ->
        update_2fa_fallbacks!(user, new_fallbacks)
        :valid
    end
  end

  defp update_2fa_fallbacks!(%User{two_factor_auth: %TwoFactorAuth{}} = user, fallbacks) do
    user.two_factor_auth
    |> TwoFactorAuth.changeset(%{fallback: fallbacks})
    |> Repo.update!()

    :ok
  end

  defp roll_fallbacks do
    plain = for _ <- 1..@fallback_count, do: Security.TwoFactorAuth.generate_fallback()
    hashed = Enum.map(plain, &Security.TwoFactorAuth.hash_fallback/1)
    {plain, hashed}
  end

  # todo is OK to _always_ preload this to make sure it's there? Should be no-op...
  defp user_preload(%User{} = user), do: Repo.preload(user, :two_factor_auth)
end
