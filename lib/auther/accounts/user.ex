defmodule Auther.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Auther.Crypto.Password

  schema "users" do
    field :email, :string
    field :name, :string

    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  @doc "Returns a changeset used to create a new account"
  def changeset_for_create(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password])
    |> validate_required([:name, :email, :password])
    |> handle_password()
  end

  def changeset_for_update(user, attrs) do
    user
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
  end

  def changeset_for_password_change(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> handle_password()
  end

  defp handle_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_confirmation(:password, required: true)
    |> hash_password()
  end

  defp hash_password(changeset) do
    cond do
      Keyword.has_key?(changeset.errors, :password) -> changeset
      Keyword.has_key?(changeset.errors, :password_confirmation) -> changeset
      true -> do_hash_password(changeset)
    end
  end

  defp do_hash_password(changeset) do
    changeset
    |> fetch_change(:password)
    |> case do
      {:ok, pw} -> put_change(changeset, :password_hash, Password.hash(pw))
      :error -> changeset
    end
    |> delete_change(:password)
  end
end