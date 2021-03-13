defmodule Auther.Security.TwoFactorAuth.TOTP do
  @behaviour Auther.Security.TwoFactorAuth

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

  defp encode_secret(secret), do: Base.encode32(secret)

  defp decode_secret(secret), do: Base.decode32!(secret)
end
