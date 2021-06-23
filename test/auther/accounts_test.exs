defmodule Auther.AccountsTest do
  use Auther.DataCase

  import Mox

  alias Auther.Accounts
  alias Auther.Accounts.{TwoFactorAuth, User}
  alias Auther.Repo
  alias Auther.Security.Encryption
  alias Auther.Security.Password.Mock, as: MockPassword
  alias Auther.Security.TwoFactorAuth.Mock, as: MockTfa

  @pw_hash "$2b$12$rMFYMFy91qV6KTPclubTVOL9gpO55.JRWDRlaZccqsdbIXZA6O8Gi"
  @valid_attrs %{
    email: "some@email.com",
    name: "some name",
    password: "asdf1234",
    password_confirmation: "asdf1234"
  }
  @update_attrs %{email: "some_updated@email.com", name: "some updated name"}
  @invalid_attrs %{email: nil, name: nil, password_hash: "anything"}

  setup :verify_on_exit!

  setup do
    stub(MockPassword, :hash, fn _ -> @pw_hash end)
    :ok
  end

  # todo migrate to use fixture() helper here as well
  # todo migrate to check error changesets for specific errors with DataCase.errors_on/2

  describe "get_user!/1" do
    test "returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end
  end

  describe "get_user_by/1" do
    test "returns the user for given clauses" do
      user_fixture(email: "test@mail.com")
      assert {:ok, %User{} = user} = Accounts.get_user_by(email: "test@mail.com")
      assert user.email == "test@mail.com"
    end

    test "returns :error for unknown clauses" do
      user_fixture(email: "other@mail.com")
      assert :error == Accounts.get_user_by(email: "test@mail.com")
    end
  end

  describe "create_user/1" do
    test "with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some@email.com"
      assert user.name == "some name"
      assert user.password_hash == @pw_hash
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "converts email address to downcase" do
      assert {:ok, %User{} = user} =
               Accounts.create_user(%{@valid_attrs | email: "TeST@SOmeWherE.dE"})

      assert user.email == "test@somewhere.de"
    end

    test "fails if email is invalid" do
      assert {:error, %Ecto.Changeset{}} =
               Accounts.create_user(%{@valid_attrs | email: "noatinhere"})
    end

    test "fails if email is already taken" do
      assert {:ok, %User{}} = Accounts.create_user(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@valid_attrs)
    end
  end

  describe "update_user/2" do
    test "with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "some_updated@email.com"
      assert user.name == "some updated name"
      # unchanged
      assert user.password_hash == @pw_hash
    end

    test "with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "with password_hash doesn't change stored password_hash" do
      user = user_fixture()
      assert {:ok, %User{} = changed_user} = Accounts.update_user(user, %{password_hash: "other"})
      assert user == changed_user
    end

    @test_pw_hash "$2b$12$hAtV1nhmVf/Ij94r/6rGJupCABIcvGK4Yv7hu3bW30KuVCJGdmsOG"

    test "with password and confirm_password updates the user" do
      MockPassword
      |> expect(:hash, fn _ -> @pw_hash end)
      |> expect(:hash, fn _ -> @test_pw_hash end)

      user = user_fixture()

      assert {:ok, %User{} = user} =
               Accounts.update_user(user, %{password: "test", password_confirmation: "test"})

      assert user.password_hash == @test_pw_hash
    end

    test "with non-matching password and confirm_passowrd returns error changeset" do
      user = user_fixture()
      expect(MockPassword, :hash, 0, fn _ -> "not_called_for_update" end)

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_user(user, %{password: "test", password_confirmation: "other"})

      assert user == Accounts.get_user!(user.id)
    end

    test "without confirm_password returns error changeset" do
      user = user_fixture()
      expect(MockPassword, :hash, 0, fn _ -> "not_called_for_update" end)

      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, %{password: "test"})
      assert user == Accounts.get_user!(user.id)
    end

    test "converts email address to downcase" do
      user = user_fixture()

      assert {:ok, %User{} = user} = Accounts.update_user(user, %{email: "TeST@SOmeWherE.dE"})
      assert user.email == "test@somewhere.de"
    end

    test "fails if email is invalid" do
      user = user_fixture()

      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, %{email: "noatinhere"})
    end

    test "fails if email is already taken" do
      assert {:ok, %User{}} = Accounts.create_user(%{@valid_attrs | email: "my@email"})

      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, %{email: "my@email"})
    end
  end

  describe "delete_user/1" do
    test "deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "deletes user and 2FA config" do
      %User{two_factor_auth: %TwoFactorAuth{id: tfa_id}} = user = fixture(:user_with_tfa)

      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(TwoFactorAuth, tfa_id) end
    end
  end

  describe "enable_2fa/3" do
    setup do
      MockTfa
      |> stub(:validate, fn "otp", "secret", [] -> {:valid, :otp} end)
      |> stub(:generate_fallback, fn -> "FALL-BACK" end)
      |> stub(:hash_fallback, fn "FALL-BACK" -> "this-is-hashed" end)

      :ok
    end

    test "creates and assosiates 2FA config, returns fallback keys" do
      user = fixture(:user)

      MockTfa
      |> expect(:generate_fallback, fn -> "FALL-B1CK" end)
      |> expect(:generate_fallback, fn -> "FALL-BA2C" end)
      |> expect(:generate_fallback, fn -> "FALL-B3AG" end)
      |> expect(:hash_fallback, fn "FALL-B1CK" -> "hash1" end)
      |> expect(:hash_fallback, fn "FALL-BA2C" -> "2hashed" end)
      |> expect(:hash_fallback, fn "FALL-B3AG" -> "3hassh" end)

      assert {:ok, %User{two_factor_auth: %TwoFactorAuth{}} = user, fallbacks} =
               Accounts.enable_2fa(user, "secret", "otp")

      assert fallbacks == ["FALL-B1CK", "FALL-BA2C", "FALL-B3AG"]
      assert user.two_factor_auth.secret == "secret"
      assert user.two_factor_auth.fallback == ["hash1", "2hashed", "3hassh"]
    end

    test "stores the 2FA secret encrypted in the database" do
      user = user_fixture()

      assert {:ok, %User{two_factor_auth: %TwoFactorAuth{} = tfa}, _fallbacks} =
               Accounts.enable_2fa(user, "secret", "otp")

      assert tfa.secret == "secret"

      [%{secret: raw_secret}] =
        Repo.all(from t in "two_factor_auth", where: [id: ^tfa.id], select: %{secret: t.secret})

      assert raw_secret != tfa.secret

      encrypted = Encryption.decrypt(raw_secret)
      assert encrypted == tfa.secret
    end

    test "stores the 2FA fallbacks hashed in the database" do
      user = fixture(:user)

      MockTfa
      |> expect(:hash_fallback, fn "FALL-BACK" -> "hash1" end)
      |> expect(:hash_fallback, fn "FALL-BACK" -> "2hashed" end)
      |> expect(:hash_fallback, fn "FALL-BACK" -> "3hassh" end)

      assert {:ok, %User{two_factor_auth: %TwoFactorAuth{} = tfa}, fallbacks} =
               Accounts.enable_2fa(user, "secret", "otp")

      assert tfa.fallback != fallbacks
      assert tfa.fallback == ["hash1", "2hashed", "3hassh"]
    end

    test "fails if secret and otp don't match" do
      expect(MockTfa, :validate, fn "invalid", "secret", [] -> :invalid end)
      user = fixture(:user)

      assert {:error, {:otp, :invalid}} = Accounts.enable_2fa(user, "secret", "invalid")
      assert user.two_factor_auth == nil
    end
  end

  describe "disable_2fa/1" do
    test "does nothing if no 2FA config is present" do
      user = user_fixture()

      assert {:ok, ^user} = Accounts.disable_2fa(user)
    end

    test "deletes 2FA config if present" do
      %User{two_factor_auth: %TwoFactorAuth{id: tfa_id}} = user = fixture(:user_with_tfa)

      assert {:ok, user} = Accounts.disable_2fa(user)
      assert user.two_factor_auth == nil
      assert Repo.get(TwoFactorAuth, tfa_id) == nil
    end
  end

  describe "has_2fa?/1" do
    test "returns true for user with two factor auth enabled" do
      assert true == Accounts.has_2fa?(fixture(:user_with_tfa))
    end

    test "returns false for user without two factor auth enabled" do
      assert false == Accounts.has_2fa?(fixture(:user))
    end
  end

  describe "verify_2fa/2" do
    test "returns :valid for OTP code matching secret" do
      expect(MockTfa, :validate, fn "otp", _secret, _fallbacks -> {:valid, :otp} end)
      user = fixture(:user_with_tfa)

      assert :valid == Accounts.verify_2fa(user, "otp")
    end

    test "returns :valid for OTP matching fallback code and updates user fallbacks" do
      expect(MockTfa, :validate, fn "otp", _secret, _fallbacks ->
        {:valid, {:fallback, ["hash1", "hash2"]}}
      end)

      user = fixture(:user_with_tfa)

      assert :valid == Accounts.verify_2fa(user, "otp")

      assert %User{two_factor_auth: %TwoFactorAuth{fallback: ["hash1", "hash2"]}} =
               Accounts.get_user!(user.id)
    end

    test "returns :valid and new fallbacks for OTP matching last fallback" do
      MockTfa
      |> expect(:validate, fn "otp", _secret, _fallbacks -> {:valid, {:fallback, []}} end)
      |> expect(:generate_fallback, fn -> "F3L1-B3CK" end)
      |> expect(:generate_fallback, fn -> "AN0T-3R1N" end)
      |> expect(:generate_fallback, fn -> "M0AR-K3Y2" end)
      |> expect(:hash_fallback, fn "F3L1-B3CK" -> "hash1" end)
      |> expect(:hash_fallback, fn "AN0T-3R1N" -> "hash2" end)
      |> expect(:hash_fallback, fn "M0AR-K3Y2" -> "hash3" end)

      user = fixture(:user_with_tfa)

      assert {:valid, {:fallback, new_fallbacks}} = Accounts.verify_2fa(user, "otp")
      assert new_fallbacks == ["F3L1-B3CK", "AN0T-3R1N", "M0AR-K3Y2"]

      %User{two_factor_auth: %TwoFactorAuth{fallback: hashed_fallbacks}} =
        Accounts.get_user!(user.id)

      assert hashed_fallbacks == ["hash1", "hash2", "hash3"]
    end

    test "returns :invalid for non-matching OTP secret and non-matching fallbacks" do
      expect(MockTfa, :validate, fn "otp", _secret, _fallback -> :invalid end)
      user = fixture(:user_with_tfa)

      assert :invalid == Accounts.verify_2fa(user, "otp")
    end
  end

  defp user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Accounts.create_user()
      |> case do
        {:ok, user} -> {:ok, Auther.Repo.preload(user, :two_factor_auth)}
        {:error, _} = err -> err
      end

    user
  end
end
