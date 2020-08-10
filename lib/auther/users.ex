defmodule Auther.Users do
  import Ecto.Query, warn: false
  alias Auther.Repo
  alias Ecto.Changeset

  alias Auther.Users.{Group, User}

  def get_user(id) do
    User
    |> Repo.get(id)
    |> Repo.preload(:groups)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def user_set_groups(%User{} = user, %Group{} = group), do: user_set_groups(user, [group])

  def user_set_groups(%User{} = user, groups) when is_list(groups) do
    user
    |> Repo.preload(:groups)
    |> Changeset.change()
    |> Changeset.put_assoc(:groups, groups)
    |> Repo.update()
  end

  def get_group(id) do
    Group
    |> Repo.get(id)
    |> Repo.preload(:users)
  end

  def create_group(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  @spec get_scopes(user :: %User{}) :: MapSet.t(String.t())
  def get_scopes(user) do
    user
    |> Repo.preload(:groups)
    |> Map.get(:groups, [])
    |> Enum.reduce(MapSet.new(), fn group, set ->
      Enum.reduce(group.scopes, set, &MapSet.put(&2, &1))
    end)
  end
end
