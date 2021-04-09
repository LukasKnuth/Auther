defmodule Auther.Accounts do
  @moduledoc """
  Context for accessing and manipulating User Accounts with Auther.
  """

  import Ecto.Query, warn: false
  alias Auther.Repo

  alias Auther.Accounts.User

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

  def change_password(%User{} = user, attrs) do
    user
    |> User.changeset_for_password_change(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @spec enable_2fa(%User{}, String.t(), [String.t()]) :: User.t()
  def enable_2fa(%User{} = user, secret, fallbacks) do
    user
    |> user_preload()
    |> User.changeset_for_enable_2fa(%{secret: secret, fallback: fallbacks})
    |> Repo.update()
  end

  def disable_2fa(%User{} = user) do
    user
    |> user_preload()
    |> User.changeset_for_disable_2fa()
    |> Repo.update()
  end

  defp user_preload(%User{} = user), do: Repo.preload(user, :two_factor_auth)
end
