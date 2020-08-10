defmodule Auther.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  alias Ecto.Changeset
  alias Auther.Users.{Group, UserGroup}

  @type t :: %__MODULE__{
          id: integer,
          email: String.t(),
          display_name: String.t(),
          groups: list(Group.t())
        }

  schema "users" do
    pow_user_fields()
    field :display_name, :string

    many_to_many :groups, Group, join_through: UserGroup

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> Changeset.cast(attrs, [:display_name])
    |> Changeset.update_change(:display_name, &String.trim/1)
  end
end
