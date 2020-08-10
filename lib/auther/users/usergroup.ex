defmodule Auther.Users.UserGroup do
  use Ecto.Schema

  alias Auther.Users.{Group, User}
  alias Ecto.Changeset

  @type t :: %__MODULE__{
          user: User.t(),
          group: Group.t(),
          inserted_at: integer
        }

  schema "users_groups" do
    belongs_to :user, User
    belongs_to :group, Group

    timestamps()
  end

  def changeset(usergroup_or_changeset, attrs) do
    usergroup_or_changeset
    |> Changeset.cast(attrs, [])
    |> Changeset.validate_required([])
  end
end
