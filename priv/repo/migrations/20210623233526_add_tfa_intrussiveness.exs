defmodule Auther.Repo.Migrations.AddTfaIntrussiveness do
  use Ecto.Migration

  def change do
    alter table(:two_factor_auth) do
      add :intrusiveness, :string
    end
  end
end
