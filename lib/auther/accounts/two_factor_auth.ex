defmodule Auther.Accounts.TwoFactorAuth do
  use Ecto.Schema
  import Ecto.Changeset

  alias Auther.Accounts.User
  alias Auther.Ecto.EncryptedType

  schema "two_factor_auth" do
    belongs_to :user, User
    field :secret, EncryptedType
    field :fallback, {:array, :string}

    field :intrusiveness, Ecto.Enum,
      values: [:aggressive, :balanced, :required],
      default: :balanced

    timestamps()
  end

  @doc "Validates that the 2FA information is always in a valid state with a secret and at least one fallback code."
  def changeset(tfa, attrs) do
    tfa
    |> cast(attrs, [:user_id, :secret, :fallback])
    |> assoc_constraint(:user)
    |> validate_required([:secret, :fallback])
    |> validate_length(:fallback, min: 1)
  end
end
