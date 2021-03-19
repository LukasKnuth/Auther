defmodule Auther.Repo.Migrations.UserAdd2fa do
  use Ecto.Migration

  def change do
    create table(:two_factor_auth) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :secret, :string
      add :fallback, {:array, :string}

      timestamps()
    end
  end
end
