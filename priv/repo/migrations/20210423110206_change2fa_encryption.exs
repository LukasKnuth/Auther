defmodule Auther.Repo.Migrations.Change2faEncryption do
  use Ecto.Migration

  def change do
    execute """
      ALTER TABLE two_factor_auth ALTER COLUMN secret TYPE bytea USING (secret::bytea)
    """
  end
end
