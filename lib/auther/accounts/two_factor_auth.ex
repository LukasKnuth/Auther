defmodule Auther.Accounts.TwoFactorAuth do
  use Ecto.Schema
  import Ecto.Changeset

  alias Auther.Accounts.User

  schema "two_factor_auth" do
    belongs_to :user, User
    field :secret, :string
    field :fallback, {:array, :string}

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
