defmodule Auther.Security.Encryption do
  use Knigge, otp_app: :auther

  @type cleartext :: binary()
  @type ciphertext :: binary()

  @doc "Encrypts a plain cleartext (any binary, such as String) into a binary ciphertext."
  @callback encrypt(cleartext()) :: ciphertext()

  @doc "Decrypts any ciphertext that was previously encrypted with this module."
  @callback decrypt(ciphertext()) :: cleartext()
end
