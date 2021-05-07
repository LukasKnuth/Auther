defmodule Auther.Security.TwoFactorAuth.TOTP do
  @behaviour Auther.Security.TwoFactorAuth

  alias Auther.Accounts.User

  @tfa_issuer "Auther"

  @impl true
  def generate_secret do
    NimbleTOTP.secret()
    |> encode_secret()
  end

  @impl true
  def valid?(secret, otp) do
    secret
    |> decode_secret()
    |> NimbleTOTP.valid?(otp)
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
