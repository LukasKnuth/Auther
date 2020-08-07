defmodule Auther.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add :name, :string
      add :description, :string
      add :scopes, {:array, :string}

      timestamps()
    end

    create table("users_groups") do
      add :user_id, references(:users)
      add :group_id, references(:groups)

      timestamps()
    end
  end
end
