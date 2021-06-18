defmodule Auther.Security.TwoFactorAuth.TOTP do
  @behaviour Auther.Security.TwoFactorAuth

  alias Auther.Accounts.User

  @tfa_issuer "Auther"
  @fallback_rand_bytes 5
  @fallback_bcrypt_rounds 11

  @impl true
  def generate_secret do
    NimbleTOTP.secret()
    |> encode_secret()
  end

  @impl true
  def generate_fallback do
    @fallback_rand_bytes
    |> :crypto.strong_rand_bytes()
    |> Base.encode32(padding: false)
    |> String.split_at(4)
    |> Tuple.to_list()
    |> Enum.join("-")
  end

  @impl true
  def hash_fallback(code) do
    Bcrypt.hash_pwd_salt(code, log_rounds: @fallback_bcrypt_rounds)
  end

  @impl true
  def validate(otp, secret, fallbacks) do
    secret = decode_secret(secret)
    if NimbleTOTP.valid?(secret, otp) do
      {:valid, :otp}
    else
      otp = String.upcase(otp)

      fallbacks
      |> Enum.find_index(&Bcrypt.verify_pass(otp, &1))
      |> case do
        nil -> :invalid
        index when is_integer(index) -> {:valid, {:fallback, List.delete_at(fallbacks, index)}}
      end
    end
  end

  @impl true
  def otpauth_uri(secret, user) do
    # According to https://github.com/google/google-authenticator/wiki/Key-Uri-Format
    user
    |> account_identifier()
    |> NimbleTOTP.otpauth_uri(decode_secret(secret), issuer: @tfa_issuer)
  end

  defp account_identifier(%User{email: email}) do
    # todo sure to use email here?
    URI.encode("#{@tfa_issuer}:#{email}")
  end

  defp encode_secret(secret), do: Base.encode32(secret)

  defp decode_secret(secret), do: Base.decode32!(secret)
end
