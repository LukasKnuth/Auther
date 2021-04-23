defmodule Auther.Ecto.EncryptedType do
  @behaviour Ecto.Type

  alias Auther.Security.Encryption

  @impl true
  def type, do: :binary

  @impl true
  def cast(value), do: {:ok, to_string(value)}

  @impl true
  def embed_as(_), do: :self

  @impl true
  def equal?(v1, v2), do: v1 == v2

  @impl true
  def dump(cleartext) do
    ciphertext =
      cleartext
      |> to_string()
      |> Encryption.encrypt()

    {:ok, ciphertext}
  end

  @impl true
  def load(encrypted), do: {:ok, Encryption.decrypt(encrypted)}
end
