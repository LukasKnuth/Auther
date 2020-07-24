defmodule Auther.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  alias Ecto.Changeset

  schema "users" do
    pow_user_fields()
    field :display_name, :string

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> Changeset.cast(attrs, [:display_name])
    |> Changeset.update_change(:display_name, &String.trim/1)
  end
end
