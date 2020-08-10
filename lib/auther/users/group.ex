defmodule Auther.Users.Group do
  use Ecto.Schema

  alias Auther.Users.{User, UserGroup}
  alias Ecto.Changeset

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          scopes: list(String.t()),
          users: list(User.t())
        }

  schema "groups" do
    field :name, :string
    field :description, :string
    field :scopes, {:array, :string}

    many_to_many :users, User, join_through: UserGroup

    timestamps()
  end

  def changeset(group_or_changeset, attrs) do
    group_or_changeset
    |> Changeset.cast(attrs, [:name, :description, :scopes])
    |> Changeset.validate_required([:name, :scopes])
    |> Changeset.update_change(:scopes, &Enum.uniq/1)
    |> Changeset.update_change(:name, &String.trim/1)
  end
end
