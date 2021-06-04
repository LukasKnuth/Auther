defmodule Auther.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Auther.Accounts.TwoFactorAuth
  alias Auther.Security.Password

  schema "users" do
    field :email, :string
    field :name, :string

    field :password, :string, virtual: true
    field :password_hash, :string

    has_one :two_factor_auth, TwoFactorAuth, on_replace: :delete

    timestamps()
  end

  @doc "Returns a changeset used to create a new account"
  def changeset_for_create(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password])
    |> validate_required([:name, :email, :password])
    |> validate_email()
    |> handle_password()
  end

  def changeset_for_update(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name, :email, :password])
    |> validate_required([:name, :email])
    |> validate_email()
    |> optional_handle_password()
  end

  def changeset_for_enable_2fa(user, tfa_attrs \\ %{}) do
    user
    |> cast(%{two_factor_auth: tfa_attrs}, [])
    |> cast_assoc(:two_factor_auth, with: &TwoFactorAuth.changeset/2, required: true)
  end

  def changeset_for_disable_2fa(user) do
    user
    |> cast(%{two_factor_auth: nil}, [])
    |> cast_assoc(:two_factor_auth, with: &TwoFactorAuth.changeset/2)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/@/)
    |> update_change(:email, &String.downcase/1)
    |> unique_constraint(:email)
  end

  defp optional_handle_password(changeset) do
    case fetch_change(changeset, :password) do
      {:ok, _} -> handle_password(changeset)
      :error -> changeset
    end
  end

  defp handle_password(changeset) do
    changeset
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
