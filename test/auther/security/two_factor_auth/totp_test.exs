defmodule Auther.Security.TwoFactorAuth.TOTPTest do
  use ExUnit.Case, async: true

  alias Auther.Security.TwoFactorAuth.TOTP

  describe "generate_fallback/0" do
    test "generates codes of the form XXXX-XXXX" do
      assert TOTP.generate_fallback() =~ ~r/^[A-Z0-9]{4}-[A-Z0-9]{4}$/
    end
  end

  describe "validate/3" do
    setup do
      secret = TOTP.generate_secret()
      fallbacks_plain = for _ <- 1..3, do: TOTP.generate_fallback()
      fallbacks_hashed = Enum.map(fallbacks_plain, &TOTP.hash_fallback/1)
      {:ok, %{secret: secret, fallbacks_plain: fallbacks_plain, fallbacks_hashed: fallbacks_hashed}}
    end

    test "returns :valid for OTP code and matching secret", %{secret: secret, fallbacks_hashed: fallbacks} do
      otp = valid_code_for(secret)
      assert {:valid, :otp} == TOTP.validate(otp, secret, fallbacks)
    end

    test "returns :valid and new list for fallback code from list", %{secret: secret} do
      fallbacks = ["8M71-I9OK", "89HH-78H8", "0LI0-LI0L"]
      hashed = Enum.map(fallbacks, &TOTP.hash_fallback/1)

      assert {:valid, {:fallback, list}} = TOTP.validate("0LI0-LI0L", secret, hashed)
      assert list == List.delete_at(hashed, 2)
    end

    test "returns :valid and new list for fallback code from list, case-insensitive", %{secret: secret} do
      fallbacks = ["TEST-1234", "H3LL-08IJ"]
      hashed = Enum.map(fallbacks, &TOTP.hash_fallback/1)

      assert {:valid, {:fallback, list}} = TOTP.validate("h3lL-08iJ", secret, hashed)
      assert list == List.delete_at(hashed, 1)
    end

    test "returns :invalid if neither OTP nor fallback code match", %{secret: secret, fallbacks_hashed: fallbacks} do
      assert :invalid == TOTP.validate("not even valid", secret, fallbacks)
    end

    test "returns :valid for OTP code with empty fallbacks", %{secret: secret} do
      otp = valid_code_for(secret)

      assert {:valid, :otp} == TOTP.validate(otp, secret, [])
    end

    test "returns :invalid for wrong OTP code and empty fallbacks", %{secret: secret} do
      assert :invalid == TOTP.validate("not valid", secret, [])
    end

    test "returns :valid and empty fallbacks if last fallback code is used", %{secret: secret} do
      fallbacks = ["LAST-ONE1"]
      hashed = Enum.map(fallbacks, &TOTP.hash_fallback/1)

      assert {:valid, {:fallback, []}} == TOTP.validate("LAST-ONE1", secret, hashed)
    end
  end

  defp valid_code_for(secret) do
    secret
    |> Base.decode32!()
    |> NimbleTOTP.verification_code()
  end
end
