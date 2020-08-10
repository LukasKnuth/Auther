defmodule Auther.Repo.Migrations.AddIndexes do
  use Ecto.Migration

  def change do
    create unique_index("users_groups", [:user_id, :group_id])
    create index("users_groups", [:user_id])
    create index("users_groups", [:group_id])
  end
end
