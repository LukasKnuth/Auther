defmodule Auther.Security.Encryption.AesTest do
  use ExUnit.Case, async: true

  alias Auther.Security.Encryption.AES

  describe "#encrypt and #decrypt" do
    test "produce compatible outputs/inputs" do
      plaintext = "hello world"
      ciphertext = AES.encrypt(plaintext)
      decrypted = AES.decrypt(ciphertext)

      assert decrypted == plaintext
    end
  end

  describe "#validate_key!" do
    test "accepts 32bytes key with Base64 encoding" do
      key = "iLNCvAiAThBplFUzHAhPty7REz9RxLgmW/akfyCyysc="

      assert key == AES.validate_key!(key)
    end

    test "raises if key isn't Base64 encoded" do
      key = "blablanotbase64lalalala"

      assert_raise RuntimeError, "Couldn't base64 decode secret key", fn ->
        AES.validate_key!(key)
      end
    end

    test "raises if key doesn't have correct Base64 padding" do
      key = "y5i2qv74yWBVc0nbnByZAhsk8SDK5JTCEBDy49DUFNw" # missing one = for padding

      assert_raise RuntimeError, "Couldn't base64 decode secret key", fn ->
        AES.validate_key!(key)
      end
    end

    test "raises if key isn't expected size" do
      key = "d+3Ak5AlB3v4nscSN2fC/4DIQmBMDn9LmS4gvUwI5g==" # only 31 bytes

      assert_raise RuntimeError, "Invalid key size. Must be 32 bytes", fn ->
        AES.validate_key!(key)
      end
    end
  end
end
