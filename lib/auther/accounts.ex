defmodule Auther.Accounts do
  @moduledoc """
  Context for accessing and manipulating User Accounts with Auther.
  """

  import Ecto.Query, warn: false
  alias Auther.Repo

  alias Auther.Accounts.User

  def get_user!(id), do: Repo.get!(User, id)

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
end
