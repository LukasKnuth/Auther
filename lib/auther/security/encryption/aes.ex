defmodule Auther.Security.Encryption.AES do
  @behaviour Auther.Security.Encryption

  @iv_size 16
  @cipher :aes_256_ctr

  @impl true
  def encrypt(cleartext) do
    iv = roll_iv()
    ciphertext = :crypto.crypto_one_time(@cipher, secret(), iv, to_string(cleartext), true)
    iv <> ciphertext
  end

  @impl true
  def decrypt(encrypted) do
    <<iv::binary-@iv_size, cipher::binary>> = encrypted
    :crypto.crypto_one_time(@cipher, secret(), iv, cipher, false)
  end

  defp roll_iv, do: :crypto.strong_rand_bytes(@iv_size)

  defp secret do
    :auther
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:secret_key)
    |> decode_key!()
  end

  @spec validate_key!(String.t()) :: String.t()
  def validate_key!(key) do
    if byte_size(decode_key!(key)) != 32 do
      raise "Invalid key size. Must be 32 bytes"
    end
    key
  end

  defp decode_key!(key) do
    case Base.decode64(key) do
      {:ok, bin_key} -> bin_key
      :error -> raise "Couldn't base64 decode secret key"
    end
  end
end
