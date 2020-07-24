defmodule Auther.Repo.Migrations.AddUserInfo do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :display_name, :string, null: false, default: ""
    end
  end
end
